#!/usr/bin/env bash
set -euo pipefail

host_os="${HOST_OS:-auto}"
insert_mode="${VOICE_INSERT_MODE:-xdotool}"
language="${VOICE_LANGUAGE:-pl}"
hotkey_keycode="${VOICE_HOTKEY_KEYCODE:-64}"
type_delay_ms="${VOICE_TYPE_DELAY_MS:-1}"
press_enter_after_type="${VOICE_PRESS_ENTER_AFTER_TYPE:-0}"
pulse_input="${VOICE_PULSE_INPUT:-default}"
input_file="${VOICE_INPUT_FILE:-}"
record_dir="${VOICE_RECORD_DIR:-/workspace/.tmp}"

mkdir -p "$record_dir"

log() {
  printf 'voice-linux-daemon: %s\n' "$*" >&2
}

normalize_transcript() {
  tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

emit_transcript() {
  local transcript="$1"
  local target_window="${2:-}"

  case "$insert_mode" in
    stdout)
      printf '%s\n' "$transcript"
      ;;
    xdotool)
      if [[ -n "$target_window" ]]; then
        xdotool windowactivate --sync "$target_window" 2>/dev/null || true
      fi

      xdotool type --clearmodifiers --delay "$type_delay_ms" -- "$transcript"

      if [[ "$press_enter_after_type" == "1" ]]; then
        xdotool key --clearmodifiers Return
      fi
      ;;
    *)
      log "unsupported VOICE_INSERT_MODE=$insert_mode"
      return 1
      ;;
  esac
}

transcribe_and_emit() {
  local audio_file="$1"
  local target_window="${2:-}"

  if [[ ! -s "$audio_file" ]]; then
    log "no audio captured at $audio_file"
    return 1
  fi

  local transcript
  transcript="$(whisper-transcribe "$audio_file" "$language" | normalize_transcript)"

  if [[ -z "$transcript" ]]; then
    log "transcript is empty"
    return 1
  fi

  emit_transcript "$transcript" "$target_window"
}

if [[ "$host_os" != "linux" && "$host_os" != "auto" ]]; then
  log "HOST_OS=$host_os, linux daemon disabled"
  exit 0
fi

if [[ -n "$input_file" ]]; then
  if [[ ! -f "$input_file" ]]; then
    log "VOICE_INPUT_FILE does not exist: $input_file"
    exit 1
  fi

  temp_audio="$(mktemp "$record_dir/voice-input.XXXXXX.wav")"
  cp "$input_file" "$temp_audio"
  trap 'rm -f -- "$temp_audio"' EXIT
  transcribe_and_emit "$temp_audio"
  exit $?
fi

if [[ -z "${DISPLAY:-}" ]]; then
  log "DISPLAY is not set"
  exit 1
fi

if [[ -z "${PULSE_SERVER:-}" ]]; then
  log "PULSE_SERVER is not set"
  exit 1
fi

for command in ffmpeg whisper-transcribe xinput; do
  if ! command -v "$command" >/dev/null 2>&1; then
    log "missing dependency: $command"
    exit 1
  fi
done

if [[ "$insert_mode" == "xdotool" ]] && ! command -v xdotool >/dev/null 2>&1; then
  log "missing dependency: xdotool"
  exit 1
fi

mapfile -t keyboard_ids < <(
  xinput list | awk '
    /slave[[:space:]]+keyboard/ && $0 !~ /XTEST|Power Button|Video Bus|Control|Microphones|hotkeys|Radio/ {
      if (match($0, /id=[0-9]+/)) {
        print substr($0, RSTART + 3, RLENGTH - 3)
      }
    }
  '
)

if [[ ${#keyboard_ids[@]} -eq 0 ]]; then
  mapfile -t keyboard_ids < <(
    xinput list | awk '
      /slave[[:space:]]+keyboard/ && $0 !~ /XTEST/ {
        if (match($0, /id=[0-9]+/)) {
          print substr($0, RSTART + 3, RLENGTH - 3)
        }
      }
    '
  )
fi

if [[ ${#keyboard_ids[@]} -eq 0 ]]; then
  log "no keyboard device found via xinput"
  exit 1
fi

fifo_path="$(mktemp -u /tmp/voice-key.XXXXXX.fifo)"
mkfifo "$fifo_path"
ffmpeg_pid=""
xinput_pids=()
audio_file=""
target_window=""

cleanup() {
  for xinput_pid in "${xinput_pids[@]}"; do
    kill "$xinput_pid" 2>/dev/null || true
  done
  [[ -n "$ffmpeg_pid" ]] && kill "$ffmpeg_pid" 2>/dev/null || true
  [[ -n "$fifo_path" ]] && rm -f "$fifo_path"
  [[ -n "$audio_file" ]] && rm -f "$audio_file"
}
trap cleanup EXIT

for keyboard_id in "${keyboard_ids[@]}"; do
  xinput test "$keyboard_id" > "$fifo_path" &
  xinput_pids+=("$!")
done

log "listening on DISPLAY=${DISPLAY} keycode=${hotkey_keycode} insert_mode=${insert_mode}"

while read -r event_type event_state event_key _; do
  if [[ "$event_type" != "key" ]]; then
    continue
  fi

  if [[ "$event_key" != "$hotkey_keycode" ]]; then
    continue
  fi

  if [[ "$event_state" == "press" ]] && [[ -z "$ffmpeg_pid" ]]; then
    audio_file="$(mktemp "$record_dir/voice-input.XXXXXX.wav")"
    target_window=""

    if [[ "$insert_mode" == "xdotool" ]]; then
      target_window="$(xdotool getactivewindow 2>/dev/null || true)"
    fi

    ffmpeg -nostdin -loglevel error -y -f pulse -i "$pulse_input" -ar 16000 -ac 1 "$audio_file" &
    ffmpeg_pid=$!
    log "recording started"
    continue
  fi

  if [[ "$event_state" == "release" ]] && [[ -n "$ffmpeg_pid" ]]; then
    # Debounce X11 auto-repeat: check if a "press" event for our hotkey arrives immediately.
    is_repeat=false
    while read -t 0.01 -r next_type next_state next_key _; do
      if [[ "$next_type" == "key" && "$next_key" == "$hotkey_keycode" ]]; then
        if [[ "$next_state" == "press" ]]; then
          is_repeat=true
          break
        fi
      fi
    done

    if [[ "$is_repeat" == "true" ]]; then
      continue
    fi

    kill "$ffmpeg_pid" 2>/dev/null || true
    wait "$ffmpeg_pid" 2>/dev/null || true
    ffmpeg_pid=""

    if transcribe_and_emit "$audio_file" "$target_window"; then
      log "transcript delivered"
    else
      log "transcription failed"
    fi

    rm -f "$audio_file"
    audio_file=""
    target_window=""
  fi
done < "$fifo_path"
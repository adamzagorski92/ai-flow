#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
record_dir="$project_root/.tmp"
mkdir -p "$record_dir"
output_file="$record_dir/voice_input.wav"
input_file="${VOICE_INPUT_FILE:-}"
lang="${1:-pl}"

ffmpeg_pid=""
xinput_pids=()
fifo_path=""

record_cmd=()

cleanup_runtime() {
  for xinput_pid in "${xinput_pids[@]}"; do
    kill "$xinput_pid" 2>/dev/null || true
  done
  [[ -n "$ffmpeg_pid" ]] && kill "$ffmpeg_pid" 2>/dev/null || true
  [[ -n "$fifo_path" ]] && rm -f "$fifo_path"
}

cleanup_all() {
  cleanup_runtime
  rm -f "$output_file"
}
trap cleanup_all EXIT

if [[ -n "$input_file" ]]; then
  if [[ ! -f "$input_file" ]]; then
    echo "VOICE_INPUT_FILE does not exist: $input_file" >&2
    exit 1
  fi

  cp "$input_file" "$output_file"
else
  if ! command -v xinput &>/dev/null; then
    echo "xinput is required. Install: sudo apt install xinput" >&2
    exit 1
  fi

  if ! command -v ffmpeg &>/dev/null && ! command -v arecord &>/dev/null; then
    echo "Install ffmpeg or alsa-utils (arecord)." >&2
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
    echo "No keyboard device found via xinput." >&2
    exit 1
  fi

  echo "Hold Alt to record. Release to transcribe." >&2

  fifo_path="$(mktemp -u /tmp/voice-key.XXXXXX.fifo)"
  mkfifo "$fifo_path"

  if command -v ffmpeg &>/dev/null; then
    record_cmd=(ffmpeg -y -f pulse -i default "$output_file")
  else
    record_cmd=(arecord -f cd -t wav "$output_file")
  fi

  for keyboard_id in "${keyboard_ids[@]}"; do
    xinput test "$keyboard_id" > "$fifo_path" &
    xinput_pids+=("$!")
  done

  while read -r type state key _; do
    if [[ "$type" != "key" ]]; then continue; fi
    if [[ "$key" != "64" ]]; then continue; fi

    if [[ "$state" == "press" ]] && [[ -z "$ffmpeg_pid" ]]; then
      "${record_cmd[@]}" 2>/dev/null &
      ffmpeg_pid=$!
      echo "Recording..." >&2
    fi

    if [[ "$state" == "release" ]] && [[ -n "$ffmpeg_pid" ]]; then
      kill "$ffmpeg_pid" 2>/dev/null || true
      wait "$ffmpeg_pid" 2>/dev/null || true
      ffmpeg_pid=""
      break
    fi
  done < "$fifo_path"

  cleanup_runtime
fi

if [[ ! -f "$output_file" ]]; then
  echo "No audio recorded." >&2
  exit 1
fi

cd "$project_root"
docker compose exec -T workbench whisper-transcribe "/workspace/.tmp/voice_input.wav" "$lang"

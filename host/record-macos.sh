#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
record_dir="$project_root/.tmp"
mkdir -p "$record_dir"
output_file="$record_dir/voice_input.wav"
lang="${1:-pl}"

if ! command -v ffmpeg &>/dev/null; then
  echo "ffmpeg is required. Install: brew install ffmpeg" >&2
  exit 1
fi

echo "Hold Option (Alt) to record. Release to transcribe." >&2

ffmpeg_pid=""
trap '[[ -n "$ffmpeg_pid" ]] && kill "$ffmpeg_pid" 2>/dev/null || true; rm -f "$output_file"' EXIT

while true; do
  alt_pressed=$(osascript -e 'tell application "System Events" to get key down of option key' 2>/dev/null)

  if [[ "$alt_pressed" == "true" ]]; then
    if [[ -z "$ffmpeg_pid" ]]; then
      ffmpeg -y -f avfoundation -i ":0" "$output_file" 2>/dev/null &
      ffmpeg_pid=$!
      echo "Recording..." >&2
    fi
  else
    if [[ -n "$ffmpeg_pid" ]]; then
      kill "$ffmpeg_pid" 2>/dev/null || true
      wait "$ffmpeg_pid" 2>/dev/null || true
      ffmpeg_pid=""
      break
    fi
  fi

  sleep 0.05
done

if [[ ! -f "$output_file" ]]; then
  echo "No audio recorded." >&2
  exit 1
fi

cd "$project_root"
docker compose exec -T workbench whisper-transcribe "/workspace/.tmp/voice_input.wav" "$lang"

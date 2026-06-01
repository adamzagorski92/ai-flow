#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  cat <<'EOF'
Usage: whisper-transcribe /path/to/audio.wav [language]

Examples:
  whisper-transcribe sample.wav
  whisper-transcribe sample.wav pl
EOF
  exit 1
fi

audio_file="$1"
language="${2:-auto}"
model_name="${WHISPER_MODEL:-large-v3-turbo}"
model_dir="${WHISPER_MODEL_DIR:-/opt/whisper/models}"
model_path="${model_dir}/ggml-${model_name}.bin"

if [[ ! -f "$audio_file" ]]; then
  echo "Audio file not found: $audio_file" >&2
  exit 1
fi

if [[ ! -f "$model_path" ]]; then
  /usr/local/bin/install-whisper-model.sh
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

threads="$(nproc)"
if [[ "$threads" -gt 4 ]]; then
  # Whisper.cpp is most efficient when bound to physical cores (typically nproc / 2)
  threads=$(( threads / 2 ))
elif [[ "$threads" -gt 2 ]]; then
  threads=$(( threads - 1 ))
fi

output_prefix="$tmp_dir/transcript"
command=(whisper-cli -m "$model_path" -f "$audio_file" -otxt -of "$output_prefix" -t "$threads" -bs 1 -bo 1 -nf)

if [[ "$language" != "auto" ]]; then
  command+=( -l "$language" )
fi

"${command[@]}" >/dev/null
cat "${output_prefix}.txt"

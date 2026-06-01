#!/usr/bin/env bash
set -euo pipefail

model_name="${WHISPER_MODEL:-base}"
model_dir="${WHISPER_MODEL_DIR:-/opt/whisper/models}"
model_file="ggml-${model_name}.bin"
default_url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${model_file}"
model_url="${WHISPER_MODEL_URL:-$default_url}"
target_path="${model_dir}/${model_file}"

mkdir -p "$model_dir"

if [[ -f "$target_path" ]]; then
  exit 0
fi

tmp_path="${target_path}.tmp"
curl -fsSL "$model_url" -o "$tmp_path"
mv "$tmp_path" "$target_path"

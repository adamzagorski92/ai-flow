#!/usr/bin/env bash
set -euo pipefail

model_name="${WHISPER_MODEL:-large-v3-turbo}"
model_dir="${WHISPER_MODEL_DIR:-/opt/whisper/models}"
model_file="ggml-${model_name}.bin"
default_url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${model_file}"
model_url="${WHISPER_MODEL_URL:-$default_url}"
target_path="${model_dir}/${model_file}"

mkdir -p "$model_dir"

if [[ -f "$target_path" ]]; then
  exit 0
fi

tmp_path="$(mktemp "${target_path}.XXXXXX.tmp")"

cleanup() {
  rm -f "$tmp_path"
}
trap cleanup EXIT

curl -fL --retry 3 --retry-delay 2 "$model_url" -o "$tmp_path"

if [[ -f "$target_path" ]]; then
  exit 0
fi

mv -n "$tmp_path" "$target_path"
trap - EXIT

if [[ -f "$tmp_path" ]]; then
  rm -f "$tmp_path"
fi

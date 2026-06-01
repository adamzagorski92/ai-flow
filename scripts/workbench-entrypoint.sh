#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.config" "$HOME/.local/share"

app_code_name="${APP_CODE_NAME:-moja-aplikacja}"
app_code_dir="${APP_CODE_DIR:-/workspace/apps/$app_code_name}"

mkdir -p /workspace/apps "$app_code_dir"

if [[ -n "${GIT_AUTHOR_NAME:-}" ]]; then
  git config --global user.name "$GIT_AUTHOR_NAME"
fi

if [[ -n "${GIT_AUTHOR_EMAIL:-}" ]]; then
  git config --global user.email "$GIT_AUTHOR_EMAIL"
fi

git config --global --add safe.directory /workspace || true
git config --global --add safe.directory "$app_code_dir" || true

if [[ -n "${GH_TOKEN:-}" ]]; then
  export GITHUB_TOKEN="$GH_TOKEN"
fi

/usr/local/bin/install-whisper-model.sh || true

if [[ $# -gt 0 ]]; then
  exec "$@"
fi

exec sleep infinity

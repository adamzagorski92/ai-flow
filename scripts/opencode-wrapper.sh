#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  -h|--help|-v|--version|version)
    exec /usr/local/bin/opencode-real "$@"
    ;;
esac

provider="${OPENCODE_PROVIDER:-opencode}"

case "$provider" in
  opencode)
    export OPENCODE_ENABLED_PROVIDER="opencode"
    export OPENCODE_RESOLVED_MODEL="opencode/${OPENCODE_ZEN_MODEL_ID:-kimi-k2.6}"
    export OPENCODE_RESOLVED_SMALL_MODEL="opencode/${OPENCODE_ZEN_SMALL_MODEL_ID:-gpt-5.4-nano}"
    ;;
  openrouter)
    export OPENCODE_ENABLED_PROVIDER="openrouter"
    export OPENCODE_RESOLVED_MODEL="openrouter/${OPENROUTER_MODEL_ID:-moonshotai/kimi-k2}"
    export OPENCODE_RESOLVED_SMALL_MODEL="openrouter/${OPENROUTER_SMALL_MODEL_ID:-openai/gpt-4.1-mini}"

    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
      cat >&2 <<'EOF'
This repo is currently configured to use the OpenRouter provider.

OPENROUTER_API_KEY is missing.

Set it in /workspace/.env and recreate the container:
  docker compose up -d --force-recreate

If you only want a one-off shell session, export it manually:
  export OPENROUTER_API_KEY=...

To switch to OpenCode Zen instead, set:
  OPENCODE_PROVIDER=opencode
EOF
      exit 1
    fi
    ;;
  *)
    cat >&2 <<EOF
Unsupported OPENCODE_PROVIDER value: $provider

Supported values:
  opencode
  openrouter
EOF
    exit 1
    ;;
esac

exec /usr/local/bin/opencode-real "$@"
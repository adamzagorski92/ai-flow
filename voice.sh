#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"

env_host_os=""
if [[ -f "$dir/.env" ]]; then
  env_host_os="$({
    awk -F= '
      /^[[:space:]]*HOST_OS[[:space:]]*=/ {
        value = substr($0, index($0, "=") + 1)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        if ((value ~ /^".*"$/) || (value ~ /^\047.*\047$/)) {
          value = substr(value, 2, length(value) - 2)
        }
        print value
        exit
      }
    ' "$dir/.env"
  } || true)"
fi

host_os="${HOST_OS:-${env_host_os:-auto}}"

if [[ -z "$host_os" || "$host_os" == "auto" ]]; then
  case "$(uname -s)" in
    Darwin) host_os="macos" ;;
    Linux)  host_os="linux" ;;
    *)
      echo "Unknown OS. Set HOST_OS in .env (macos, linux, windows)." >&2
      exit 1
      ;;
  esac
fi

case "$host_os" in
  macos)   exec "$dir/host/record-macos.sh" "$@" ;;
  linux)   exec "$dir/host/record-linux.sh" "$@" ;;
  windows)
    if command -v pwsh &>/dev/null; then
      exec pwsh -File "$dir/host/record-windows.ps1" "$@"
    elif command -v powershell.exe &>/dev/null; then
      exec powershell.exe -File "$dir/host/record-windows.ps1" "$@"
    else
      echo "PowerShell not found. Run directly: host/record-windows.ps1" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unsupported HOST_OS: $host_os (use: macos, linux, windows)." >&2
    exit 1
    ;;
esac

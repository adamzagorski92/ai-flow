#!/usr/bin/env bash
set -euo pipefail

docker compose exec workbench bash -lc 'cd "$APP_CODE_DIR" && exec bash'
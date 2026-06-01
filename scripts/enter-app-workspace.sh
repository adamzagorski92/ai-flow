#!/usr/bin/env bash
set -euo pipefail

docker compose exec workbench bash -lc 'cd /workspace/apps && exec bash'
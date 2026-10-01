#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(unset CDPATH; cd -- "$SCRIPT_DIR/.." && pwd)
cd "$PROJECT_ROOT"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command is missing: $1"
}

require_project() {
  require_command docker
  docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 is unavailable"
  [ -f .env ] || fail "Missing .env. Run: make init"
}

compose() {
  docker compose "$@"
}

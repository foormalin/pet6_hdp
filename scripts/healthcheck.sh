#!/usr/bin/env sh

set -eu
# shellcheck source=scripts/common.sh
. "$(dirname -- "$0")/common.sh"

require_project

wait_mode=false
if [ "${1:-}" = "--wait" ]; then
  wait_mode=true
fi

services=${HEALTH_SERVICES:-"db glpi nginx prometheus grafana blackbox-exporter mysql-exporter cadvisor node-exporter"}
timeout=${HEALTH_TIMEOUT:-240}
started_at=$(date +%s)

container_state() {
  service=$1
  container_id=$(compose ps -q "$service")
  [ -n "$container_id" ] || {
    printf '%s' missing
    return
  }

  docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || printf '%s' unknown
}

while :; do
  all_ready=true
  printf '%-20s %s\n' SERVICE STATE
  printf '%-20s %s\n' '--------------------' '----------'

  for service in $services; do
    state=$(container_state "$service")
    printf '%-20s %s\n' "$service" "$state"
    case "$state" in
      healthy|running) ;;
      *) all_ready=false ;;
    esac
  done

  if [ "$all_ready" = true ]; then
    break
  fi

  [ "$wait_mode" = true ] || fail "One or more services are not ready"
  now=$(date +%s)
  elapsed=$((now - started_at))
  [ "$elapsed" -lt "$timeout" ] || fail "Services did not become healthy within ${timeout}s"
  printf 'Waiting for the stack to become healthy...\n\n'
  sleep 5
done

# Variables in this command expand inside the database container.
# shellcheck disable=SC2016
compose exec -T db sh -ec 'mariadb --user=root --password="$MARIADB_ROOT_PASSWORD" --execute="SELECT 1" "$MARIADB_DATABASE" >/dev/null'

if command -v curl >/dev/null 2>&1; then
  http_port=8080
  while IFS='=' read -r key value; do
    if [ "$key" = "HTTP_PORT" ] && [ -n "$value" ]; then
      http_port=$(printf '%s' "$value" | tr -d '\r')
    fi
  done <.env
  curl --fail --silent --show-error --max-time 10 "http://127.0.0.1:${http_port}/healthz" >/dev/null
  printf '\nHTTP endpoint: healthy\n'
fi

printf 'Database query: healthy\n'
printf 'Stack status: healthy\n'

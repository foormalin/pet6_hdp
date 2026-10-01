#!/usr/bin/env sh

set -eu
# shellcheck source=scripts/common.sh
. "$(dirname -- "$0")/common.sh"

require_project
require_command gzip
require_command sha256sum

backup_dir=${1:-}
[ -n "$backup_dir" ] || fail "Usage: $0 backups/<timestamp>"
[ -d "$backup_dir" ] || fail "Backup directory does not exist: $backup_dir"
[ -f "$backup_dir/database.sql.gz" ] || fail "Missing database.sql.gz"
[ -f "$backup_dir/glpi-files.tar.gz" ] || fail "Missing glpi-files.tar.gz"
[ -f "$backup_dir/SHA256SUMS" ] || fail "Missing SHA256SUMS"

(
  cd "$backup_dir"
  sha256sum --check SHA256SUMS
)

db_name=$(compose exec -T db printenv MARIADB_DATABASE | tr -d '\r')
expected="RESTORE $db_name"
printf 'This replaces database "%s" and the GLPI data volume.\n' "$db_name"
printf 'Type "%s" to continue: ' "$expected"
if [ -n "${CONFIRM_RESTORE:-}" ]; then
  answer=$CONFIRM_RESTORE
  printf '%s\n' "$answer"
else
  read -r answer
fi
[ "$answer" = "$expected" ] || fail "Confirmation did not match"

backup_abs=$(unset CDPATH; cd -- "$backup_dir" && pwd)
if command -v cygpath >/dev/null 2>&1; then
  backup_abs=$(cygpath -w "$backup_abs")
fi
glpi_container=$(compose ps -q glpi)
[ -n "$glpi_container" ] || fail "GLPI container must exist before restore"

restart_frontend() {
  compose up -d glpi nginx >/dev/null 2>&1 || true
}
trap restart_frontend EXIT INT TERM

printf 'Stopping application traffic...\n'
compose stop nginx glpi >/dev/null

printf 'Recreating the target database...\n'
# Variables in these commands expand inside the database container.
# shellcheck disable=SC2016
compose exec -T db sh -ec 'mariadb --user=root --password="$MARIADB_ROOT_PASSWORD" --execute="DROP DATABASE IF EXISTS \`$MARIADB_DATABASE\`; CREATE DATABASE \`$MARIADB_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; GRANT ALL PRIVILEGES ON \`$MARIADB_DATABASE\`.* TO \`$MARIADB_USER\`@\`%\`; FLUSH PRIVILEGES;"'
# shellcheck disable=SC2016
gzip -dc "$backup_dir/database.sql.gz" \
  | compose exec -T db sh -ec 'exec mariadb --user=root --password="$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"'

printf 'Restoring GLPI configuration and files...\n'
MSYS_NO_PATHCONV=1 docker run --rm \
  --volumes-from "$glpi_container" \
  --mount "type=bind,src=$backup_abs,dst=/backup,readonly" \
  alpine:3.22 \
  sh -ec 'find /var/glpi -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; tar -xzf /backup/glpi-files.tar.gz -C /var/glpi'

printf 'Starting application traffic...\n'
compose up -d glpi nginx >/dev/null
trap - EXIT INT TERM

"$SCRIPT_DIR/healthcheck.sh" --wait
printf 'Restore completed from: %s\n' "$backup_dir"

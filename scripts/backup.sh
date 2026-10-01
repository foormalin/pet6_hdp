#!/usr/bin/env sh

set -eu
# shellcheck source=scripts/common.sh
. "$(dirname -- "$0")/common.sh"

require_project
require_command gzip
require_command sha256sum

timestamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir="backups/$timestamp"
mkdir -p "$backup_dir"
backup_abs=$(unset CDPATH; cd -- "$backup_dir" && pwd)
if command -v cygpath >/dev/null 2>&1; then
  backup_abs=$(cygpath -w "$backup_abs")
fi

db_container=$(compose ps -q db)
glpi_container=$(compose ps -q glpi)
[ -n "$db_container" ] || fail "Database container is not running"
[ -n "$glpi_container" ] || fail "GLPI container is not running"

printf 'Creating consistent database dump...\n'
# Variables in this command expand inside the database container.
# shellcheck disable=SC2016
compose exec -T db sh -ec 'exec mariadb-dump --single-transaction --quick --routines --events --user=root --password="$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' \
  | gzip -9 >"$backup_dir/database.sql.gz"

printf 'Archiving GLPI configuration and uploaded files...\n'
MSYS_NO_PATHCONV=1 docker run --rm \
  --volumes-from "$glpi_container" \
  --mount "type=bind,src=$backup_abs,dst=/backup" \
  alpine:3.22 \
  tar -czf /backup/glpi-files.tar.gz -C /var/glpi .

(
  cd "$backup_dir"
  sha256sum database.sql.gz glpi-files.tar.gz >SHA256SUMS
)

cat >"$backup_dir/manifest.txt" <<EOF
created_at=$timestamp
compose_project=${COMPOSE_PROJECT_NAME:-helpdesk}
database=${GLPI_DB_NAME:-glpi}
includes=database,glpi-files
EOF

printf 'Backup completed: %s\n' "$backup_dir"

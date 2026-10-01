#!/usr/bin/env sh

set -eu

command -v grep >/dev/null 2>&1 || {
  printf 'grep is required\n' >&2
  exit 1
}

required_files="
README.md
.env.example
.gitignore
compose.yaml
Makefile
config/nginx/default.conf
config/prometheus/prometheus.yml
config/blackbox/blackbox.yml
monitoring/grafana/provisioning/datasources/prometheus.yml
monitoring/grafana/provisioning/dashboards/dashboards.yml
monitoring/grafana/dashboards/helpdesk-overview.json
scripts/healthcheck.sh
scripts/backup.sh
scripts/restore.sh
docs/architecture.md
docs/setup.md
docs/operations.md
docs/backup-restore.md
"

for path in $required_files; do
  [ -f "$path" ] || {
    printf 'Missing required file: %s\n' "$path" >&2
    exit 1
  }
done

if command -v git >/dev/null 2>&1 && git ls-files --error-unmatch .env >/dev/null 2>&1; then
  printf '.env must not be tracked by Git\n' >&2
  exit 1
fi

if grep -R --line-number --exclude='validate_repo.sh' 'change_me_' compose.yaml config monitoring scripts; then
  printf 'Placeholder secrets are only allowed in .env.example\n' >&2
  exit 1
fi

printf 'Repository structure: valid\n'

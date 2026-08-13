#!/bin/sh
set -eu

project_dir=${GAAP_PROJECT_DIR:-/opt/gaap}
backup_dir=${GAAP_BACKUP_DIR:-/opt/gaap/backups}
encryption_key_file=${GAAP_BACKUP_KEY_FILE:-/opt/gaap/secrets/backup.key}
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
output_file="${backup_dir}/gaap-${timestamp}.sql.gz.enc"

umask 077
mkdir -p "${backup_dir}"
test -r "${encryption_key_file}"

docker compose --env-file "${project_dir}/.env.production" -f "${project_dir}/docker-compose.production.yml" exec -T postgres \
  sh -c 'exec pg_dump --format=plain --no-owner --no-privileges --username="$POSTGRES_USER" "$POSTGRES_DB"' \
  | gzip -9 \
  | openssl enc -aes-256-cbc -salt -pbkdf2 -pass "file:${encryption_key_file}" -out "${output_file}"

find "${backup_dir}" -type f -name 'gaap-*.sql.gz.enc' -mtime +7 -delete
printf '%s\n' "${output_file}"

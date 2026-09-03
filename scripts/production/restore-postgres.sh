#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  printf '%s\n' "usage: $0 /absolute/path/to/gaap-backup.sql.gz.enc" >&2
  exit 2
fi

project_dir=${GAAP_PROJECT_DIR:-/opt/gaap}
encryption_key_file=${GAAP_BACKUP_KEY_FILE:-/opt/gaap/secrets/backup.key}
backup_file=$1
restore_database=${GAAP_RESTORE_DB:-}

test -r "${backup_file}"
test -r "${encryption_key_file}"

openssl enc -d -aes-256-cbc -pbkdf2 -pass "file:${encryption_key_file}" -in "${backup_file}" \
  | gzip -dc \
  | docker compose --env-file "${project_dir}/.env.production" -f "${project_dir}/docker-compose.production.yml" exec -T postgres \
      sh -c 'exec psql --set ON_ERROR_STOP=1 --username="$POSTGRES_USER" --dbname="${1:-$POSTGRES_DB}"' sh "${restore_database}"

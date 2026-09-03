# GAAP Invite-Only Beta Production Runbook

Main release plan: `plans/release-beta-2026-08-14.md`.

## Release Prerequisites

- An Ubuntu VPS with Docker Engine and the Compose Plugin installed.
- `gaap.cc` and `www.gaap.cc` both resolve to the VPS; ports 80/443 are open.
- Cloudflare Turnstile is configured for `gaap.cc`, with Site Key and Secret as a pair.
- This release uses a brand-new PostgreSQL database; no UAT data is imported.
- RabbitMQ is a core dependency of the Dashboard refresh chain and must not be removed from the production stack just because the task center is deferred.
- Authentication now transmits the raw password inside ALE and hashes it server-side with bcrypt; legacy browser SHA-256 password records are incompatible, so pre-production test accounts must be recreated.
- The 8 historical PASS entries in `plans/uat/` have been regressed, and every CORE GATE case for this version has been executed and passed.

## Production Configuration

Copy the example file under `/opt/gaap` on the server and restrict permissions:

```sh
cp .env.production.example .env.production
chmod 600 .env.production
install -d -m 700 /opt/gaap/secrets /opt/gaap/backups
openssl rand -base64 48 > /opt/gaap/secrets/backup.key
chmod 600 /opt/gaap/secrets/backup.key
```

All example values must be replaced. `ALE_BOOTSTRAP_KEY` must exactly match the value
passed as `NEXT_PUBLIC_ALE_BOOTSTRAP_KEY` when building the Web image; it is a public browser
setting and cannot replace the JWT, database, Redis or Turnstile Secret.

## Building Immutable Images

Use release numbers or Git SHAs; never use `latest`:

```sh
docker build --target production \
  -t ghcr.io/your-org/gaap-api:2026-08-14.1 ./gaap-api

docker build --target production \
  --build-arg NEXT_PUBLIC_ALE_BOOTSTRAP_KEY="$NEXT_PUBLIC_ALE_BOOTSTRAP_KEY" \
  --build-arg NEXT_PUBLIC_TURNSTILE_SITE_KEY="$NEXT_PUBLIC_TURNSTILE_SITE_KEY" \
  -t ghcr.io/your-org/gaap-web:2026-08-14.1 ./gaap-web
```

After pushing the images, write the same immutable tags into `GAAP_API_IMAGE` and
`GAAP_WEB_IMAGE` in `.env.production`.

## Deployment & Verification

```sh
docker compose --env-file .env.production -f docker-compose.production.yml config
docker compose --env-file .env.production -f docker-compose.production.yml pull
docker compose --env-file .env.production -f docker-compose.production.yml up -d
docker compose --env-file .env.production -f docker-compose.production.yml ps
curl --fail https://gaap.cc/api/v1/health/live
curl --fail https://gaap.cc/api/v1/health/ready
```

Then follow `plans/uat/` to run the public smoke test: whitelisted registration, login, accounts,
income/expense/transfer, transaction update and delete, balance reconciliation, refresh rotation, logout, container restart recovery and HTTPS security headers.

Run a read-only ledger reconciliation before opening the whitelist; `passed` must be `true`, and both `differences` and `issues`
must be empty:

```sh
docker compose --env-file .env.production -f docker-compose.production.yml \
  run --rm --no-deps gaap-api ./reconcile
```

The command enables PostgreSQL `REPEATABLE READ, READ ONLY` before reading. Exit code `2` means a
ledger discrepancy or integrity anomaly was found; the release must be blocked and the database preserved as-is — do not manually edit balances.

## Backup & Restore

Run daily:

```sh
GAAP_PROJECT_DIR=/opt/gaap /opt/gaap/scripts/production/backup-postgres.sh
```

The restore drill must write into a separate, empty database:

```sh
GAAP_PROJECT_DIR=/opt/gaap GAAP_RESTORE_DB=gaap_restore \
  /opt/gaap/scripts/production/restore-postgres.sh /absolute/path/to/backup.sql.gz.enc
```

The backup script uses AES-256-CBC + PBKDF2 encryption and retains backups for at least 7 days. Before restoring the real production database, you must first
stop write traffic and keep a current snapshot of the database.

## Rollback

- Application failure: revert the image tag in `.env.production` to the previous release and run `up -d` again.
- Ledger or migration failure: stop write traffic, preserve the incident state, and restore from the encrypted pre-release backup; do not run a downward migration directly on a database that already has
  new writes.
- Observe for at least 2 hours after release: 5xx errors, ALE/HMAC failures, refresh loops, Redis errors, database lock waits,
  RabbitMQ connections/backlog, plus reconciliation between account balances and transaction history.
- While RabbitMQ restarts, the API ready endpoint should temporarily return 503; the connection supervisor automatically reconnects and re-registers consumers. After recovery, confirm that ready returns 200 and that `gaap.dashboard` and `gaap.tasks` each have one consumer; only if it has not recovered beyond the
  backoff window should you treat it as a failure — keep the logs in that case, and do not restart the API as a normal recovery step.

# gaap.local Local UAT

## Access & Registration

- URL: `https://gaap.local`
- Whitelisted email: `uat@gaap.local`
- Testers set their own password and nickname.
- Turnstile uses the official Cloudflare test key, so no real CAPTCHA challenges or public production data are generated.
- UAT status is only updated in `plans/uat/`; do not restore or continue editing the old Excel file.

On first visit, if the browser does not trust the local Caddy CA, you can manually open
`config/caddy/gaap-local-root.crt`, add it to the "login" keychain, and set it under
"Trust" to "Always Trust". This is a local CA and should not be copied to other devices or production servers.

## Common Commands

Start or update from the current source code:

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml up -d --build
```

Check status and logs:

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml ps
docker compose --env-file .env.uat -f docker-compose.uat.yml logs -f gaap-api gaap-web rabbitmq caddy
```

Stop the services but keep UAT data:

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml stop
```

Start again:

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml start
```

Only when you explicitly need to reset all UAT data, run the command below; it deletes the PostgreSQL, Redis,
RabbitMQ and Caddy data volumes and cannot be undone:

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml down -v
```

## UAT Execution Rules

- First re-run the 8 `CORE REGRESSION` cases.
- Then run this version's 74 `CORE GATE` cases.
- The 38 deferred cases are consolidated in `plans/uat/deferred.md`; keep them as `NOT RUN / DEFERRED`.
- When a defect is found, update `plans/uat/defects.md` with reproduction steps, severity level, fix commit and verification case.
- Do not mark manual UAT cases as `PASS` just because automated tests or smoke checks passed.

The 2026-08-13 batch `UAT-20260813-BETA-RC-01` completed 82/82 Beta cases using a real browser and the real protobuf + ALE
HTTPS chain; see `plans/uat/runs/2026-08-13-beta-rc-01.md` for execution evidence. The 38 DEFERRED cases remain NOT RUN.

# GAAP Invite-Only Beta Release Plan

Version: 2026-08-13 revision  
Target release date: 2026-08-14  
Target domain: `gaap.cc`  
Current acceptance environment: `https://gaap.local`

This document is the single main release plan for this Beta round. UAT status is governed by
`plans/uat/`, production operations by `docs/production-runbook.md`, and component keep/drop decisions by
`docs/beta-component-dependency-audit.md`.

## 1. Current Baseline & Release Scope

- The 2026-08-13 batch `UAT-20260813-BETA-RC-01` re-ran the 8 historical CORE REGRESSION cases and
  completed all 74 CORE GATE cases: 82/82 PASS, 0 FAIL, 0 NOT RUN.
- Of the original 120 cases, another 38 are DEFERRED; they remain NOT RUN and do not count toward Beta feature scope.
- Automated test baseline today: 152 backend tests and 74 standard frontend tests passing; real browser and protocol results are
  recorded separately as UAT and never substituted by unit tests.
- Production uses a brand-new PostgreSQL database; no UAT data is imported.
- The Beta uses server-side email whitelisting, low-concurrency invitation-only access, and a single base currency per user.

Open in the first version:

- Whitelisted registration;
- Login, refresh, logout, and independent multi-device sessions;
- Asset, liability, income and expense accounts;
- Income, expense and transfer transactions, plus transaction update and delete;
- Basic Dashboard with a 30-day balance trend;
- live, ready, and HTTPS.

Deferred in the first version:

- 2FA setup and enabling;
- Password change;
- Migration-delete for accounts that have transactions;
- Pro users, account groups and sub-accounts;
- Task center and data import/export;
- WebSocket user entry point;
- Exchange rates, multi-currency accounts and converted valuations.

## 2. Production Component Baseline

Both production and UAT deploy: Caddy, Next.js Web, GoFrame API, PostgreSQL, Redis and RabbitMQ.

RabbitMQ is a core dependency of the Dashboard snapshot refresh chain and can no longer be removed just because the task center is deferred.
RabbitMQ, PostgreSQL and Redis join only the Docker internal data network; no business ports are exposed to the public internet or the host machine.

The API startup must connect successfully to PostgreSQL, Redis and RabbitMQ and complete migrations before it starts; ready additionally checks:

- PostgreSQL is queryable;
- Redis/ALE is available;
- The RabbitMQ connection is still alive;
- All `manifest/sql` migrations are recorded.

When any core dependency is unavailable, the API must not accept traffic. When RabbitMQ restarts while running, ready returns 503;
the connection supervisor reconnects automatically via backoff — the 2026-08-13 UAT recovered ready to 200 within 17 seconds and both `gaap.dashboard` and `gaap.tasks` each auto-recovered one consumer without an API restart.

## 3. Core Remediation Status

### UAT & Defect Baseline

- **Done**: the Excel workbook was split into `plans/uat/` Markdown files; the old Excel is deprecated.
- **Done**: the 8 historical PASS entries and all other NOT RUN/DEFERRED statuses were recorded according to actual results.
- **Done**: the original Bug, TODO and newly found UAT issues were merged into `plans/uat/defects.md`.
- **Done**: the 2026-08-12 manual UAT batch passed; its scope is recorded in
  `plans/uat/manual-runs.md`.
- **Done**: full UAT results mapped onto the 82 Beta cases, with evidence in
  `plans/uat/runs/2026-08-13-beta-rc-01.md`.
- **Gate**: core cases must not remain NOT RUN; DEFERRED entries must not be written as PASS.

### ALE + Protobuf

- **Done**: business requests converge on `secureRequest + protobuf + ALE`.
- **Done**: unified protobuf error structure and 401 marker for lost sessions.
- **Done**: JWTs use `sid`, Redis sessions are isolated per user and device, and refresh keeps the sid while rotating tokens.
- **Done**: when a Redis session key is missing, a recognizable 401 is returned without exposing raw
  `OperationError` to users.
- **Gate passed**: tampering, replay, expired timestamps, invalid sids, sensitive log scanning, and independent multi-device
  refresh/logout all passed.

### Ledger Safety & Dashboard

- **Done**: validation for transaction account ownership, account type, currency, amount, same-account cases and sort fields.
- **Done**: creating, updating and deleting transactions use database transactions; caches are invalidated and the Dashboard refreshed only after commit.
- **Done**: accounts are locked in fixed UUID order, and updates check the number of affected rows.
- **Done**: backend amounts use `shopspring/decimal`; frontend amounts use Decimal.js.
- **Done**: transaction and account changes invalidate both stale Redis and PostgreSQL Dashboard snapshots at once; the frontend also invalidates its Dashboard Query at the same time.
- **Done**: API startup rebuilds the Dashboard from the source-of-truth accounts and transactions, instead of restoring possibly stale persisted snapshots directly.
- **Done**: the RabbitMQ Dashboard worker starts in UAT/production modes, and the API/ready fails closed on RabbitMQ.
- **Done**: accounts with transactions are refused for deletion by the backend; the frontend no longer shows a migration-delete UI.
- **Automated gate done**: trends after creating/updating/deleting historical-date transactions; fixed UUID order row locks;
  transaction rollback when the second account update fails; ledger recalculation across all account types plus a 1-nano difference boundary.
- **UAT passed**: final read-only reconciliation checked 142 accounts and 62 valid transactions with no balance discrepancies or integrity anomalies; real browser and protocol runs confirmed that after creating, date-moving and deleting historical transactions, the 30-day trend converges correctly.
- **UAT passed**: account group and sub-account success paths are deferred; Free/Beta users submitting `is_group`
  or `parent_id` directly are all rejected, with no dirty writes to accounts or opening-balance transactions.

### Startup Balances & Reconciliation Policy

The old startup balance recalculation queried integer transaction enums with strings and only covered some transaction directions and account types. A minimal "just runnable" fix could have batch-corrupted balances at startup.

Policy for this version:

- **Done**: automatic balance rewriting was removed from the production/UAT startup chain;
- Account balances are updated and persisted solely by database transactions on transaction create/update/delete;
- Startup only rebuilds derived Dashboard data — no silent ledger repair;
- **Done**: added a reconciliation command that enforces PostgreSQL `READ ONLY`, covering assets, liabilities, income, expense, equity, opening balances and transfers; it exits non-zero when differences are found and never writes back data.

### Production Operational Readiness

- **Done**: versioned migrations, production images, non-root/read-only containers, Caddy, PostgreSQL, Redis and RabbitMQ Compose.
- **Done**: `/v1/health/live` and `/v1/health/ready`.
- **Done**: local encrypted backup and an independent restore-database drill.
- **Done**: the `gaap.local` HTTPS UAT environment.
- **Done**: production Secrets generated and deployed with `0600` permissions; API/Web use verified exact digests for `linux/amd64`, and production infrastructure started 5 migrations.
- **Done**: on the VPS, API/Web/PostgreSQL/Redis/RabbitMQ are healthy; both RabbitMQ queues have one consumer each with no backlog; read-only reconciliation of the empty production DB passed.
- **Partially done**: during a RabbitMQ restart ready returned 503 and recovered in 14 seconds; Redis and API restarts recovered in 0 and 1 second respectively; post-restart read-only reconciliation passed again.
- **Resolved**: Cloudflare DNS, orange cloud, HTTPS and security headers restored; a leftover historical Origin Rule had mis-forwarded `gaap.cc` to VPS port `8081`, causing 525s — after deleting it, real Turnstile and the public business smoke both passed.
- **WAIVED / ACCEPTED RISK**: the release owner confirmed at 12:15 CST on 2026-08-14 that this round does not require production backups, an independent restore drill or daily backup jobs; these three items were removed from the Beta release gate and are not written as PASS. The risk of having no verifiable production restore point on database failure — with no guarantee of recovering the latest data — is accepted.

## 4. Testing & Release Gates

Automated gates:

- Go 1.24: `go test ./...`;
- Node 22: Vitest, ESLint and TypeScript;
- No drift in protobuf/GoFrame generated code;
- Both API and Web production image builds;
- UAT and production Compose config validation.

Manual and integration gates:

- All 8 historical PASS entries re-passed;
- All 74 CORE GATE cases executed and passed;
- Whitelisted registration, login, refresh and logout;
- Create asset, liability, income and expense accounts;
- Create income, expense and transfer transactions;
- Update and delete transactions while verifying both sides' balances;
- Historical-date transactions produce changes on the correct dates in the Dashboard;
- Both RabbitMQ queues have consumers and no backlog of Dashboard messages;
- Session, ready and Dashboard behavior after Redis/RabbitMQ/API restarts match expectations;
- Read-only ledger reconciliation has zero differences;
- HTTPS and Turnstile completed.

Any single one of these failures stops the release immediately: ledger inconsistency, authorization bypass, ALE leakage or undecryptable data, core P0/P1 defects, lost RabbitMQ/Dashboard refreshes, or migration failure.

## 5. Revised Timeline

### Wednesday, August 12

- **Done**: fixes for ALE session-lost 401s, instantly created spending accounts and the missing Dashboard historical transactions.
- **Done**: RabbitMQ added to the UAT/production stack; API/ready fail closed.
- **Done**: component dependency audit, retirement of startup automatic balance rewriting, convergence of migration-delete UI.
- **Done**: manual UAT batch passed (user confirmed on 2026-08-13); per-case scope and evidence continue to be reconciled against the
  `plans/uat/` status.

### Thursday, August 13

- **Done**: DEF-019 fixed with a full protocol retest that bypasses the UI;
- **Done**: the 8 historical regressions plus all 74 CORE GATE cases;
- **Done**: read-only ledger reconciliation, concurrency, fault rollback, historical-date Dashboard and RabbitMQ auto-recovery gates;
- **Done**: release branches and draft PRs for the three repos, API/Web candidate images with immutable digests; the production candidate was deployed on isolated ports under `/opt/gaap` — migrations, health checks, consumers, dependency restarts and empty-DB reconciliation all passed.
- **Done**: Cloudflare DNS and Caddy HTTPS/security headers restored; real Turnstile issued tokens, and whitelisted production registration for `windane@gmail.com` passed. Execution crossed 2026-08-14 00:00; the remaining production smoke moved into the daytime of August 14 and is not back-dated as completed on August 13.
- **Decision at that time**: production backups, an independent restore drill and daily backup jobs would not be run this round — status held at NO-GO until then; that decision was updated to a formal waiver by the release owner at 12:15 CST on 2026-08-14.

### Friday morning, August 14

- **Done**: with orange cloud enabled and Cloudflare bypassed, direct connection to `144.34.237.205` confirmed requests reach the origin directly; TLS certificate, HTTP→HTTPS, Web/Caddy routing, API ready and security response headers all passed;
- **Done**: a historical Cloudflare Origin Rule had mis-forwarded `gaap.cc` to VPS port `8081`, triggering 525s; after deleting the rule and restoring the public login page, production re-registration, login, four account types, income/expense/transfer, transaction update and delete, Dashboard, refresh and logout smoke all passed;
- **Done**: the production read-only ledger reconciliation checked 6 accounts and 4 transactions with `passed=true`, `differences=[]` and `issues=[]`; both RabbitMQ queues have one consumer each with no backlog; final application logs show no ERROR/WARN/PANIC/FATAL or 5xx; browser console has no errors — newly found chart sizing and Dialog accessibility warnings plus the transaction time control/date protocol mismatch were recorded as non-blocking DEF-025/026/027;
- **Done (overdue wrap-up)**: the release owner confirmed the final GO at 12:15 CST on 2026-08-14; by 12:22 CST, production evidence had been updated, docs committed and pushed, PR checks passed, and the root/API/Web workspaces were all confirmed clean;
- **Confirmed**: Caddyfile permissions restored by the release owner; Cloudflare orange cloud enabled with normal public access;
- **WAIVED / ACCEPTED RISK**: pre-release database backups, an independent restore drill and daily backup jobs are not executed this round and no longer block release.

### Friday afternoon, August 14

- Deploy `gaap.cc`;
- Run the public smoke for registration, login, accounts, transactions, Dashboard, refresh, logout, HTTPS and container restart;
- Open the email whitelist once all smoke checks pass;
- Observe for at least 2 hours: 5xx errors, ALE, refresh loops, RabbitMQ connections/backlog, database lock waits and ledger reconciliation.

Application failure rolls back to the previous immutable image; a database failure first stops write traffic and preserves the scene. Because this round has waived the production backup/restore gate, no usable restore point is guaranteed; blind downward migrations on a database that already has new writes are forbidden.

## 6. Current Go / No-Go Decision

Confirmed by the release owner at 12:15 CST on 2026-08-14, with doc push and PR checks completed by 12:22 CST:
**final conclusion is GO (invite-only Beta)**.

Local RC, VPS containers, DNS/HTTPS, real Turnstile, origin direct connection, production business smoke, RabbitMQ re-check,
production read-only reconciliation and the final application log scan all passed. No unresolved Beta P0/P1 remains; DEF-025/026/027 are documented non-blocking P2s.

The release owner explicitly removed production backups, an independent restore drill and daily backups from this round's Beta gate, recorded as **WAIVED / ACCEPTED RISK** rather than PASS. This waiver does not change the technical outcome but means a database failure has no verifiable production restore point, so recovering the latest business data may not be possible. At least 2 hours of post-release observation will continue.

## 7. Candidate Artifact Record

- UAT batch: `UAT-20260813-BETA-RC-01` (82/82 PASS).
- API commit: `2a163356eca1b5edb6b66a87a467aadeddf37dcb`.
- Web commit: `6862ca2825b0b2da86760ada4a84507f46c47eaf`.
- API candidate tag:
  `ghcr.io/gin-melodic/gaap-api:beta-2026-08-14-2a163356eca1b5edb6b66a87a467aadeddf37dcb`.
- Web candidate tag:
  `ghcr.io/gin-melodic/gaap-web:beta-2026-08-14-6862ca2825b0b2da86760ada4a84507f46c47eaf`.
- API digest: `sha256:7e7546fef26de2da228c13b9db4658dddc1cf439d6b93e1773dcfc3ac75e5be8`.
- Web digest: `sha256:4c3ef686d0085c854695f2fb1ba74a7b06010e641a888c4f362ed32c7191e3fc`.
- Root candidate infrastructure commit: `826b5cf46587554526710cc83f79b3045ac2f9b2`.
- Draft PRs: root repo [#2](https://github.com/gin-melodic/gaap/pull/2), API
  [#5](https://github.com/gin-melodic/gaap-api/pull/5) and Web
  [#8](https://github.com/gin-melodic/gaap-web/pull/8).
- API/Web/root CI: PASS.
- GitHub Actions secrets include `BETA_ALE_BOOTSTRAP_KEY` and `BETA_TURNSTILE_SITE_KEY`; secret values are not recorded in the evidence files.
- VPS Compose uses the above `image@sha256:...` references; no `latest` was deployed — execution evidence is in
  [`UAT-20260813-VPS-RC-01`](uat/runs/2026-08-13-vps-rc-01.md).

# Automated Smoke Records

This file records engineering verification and does not change any UAT case status. Only after manual per-case execution with evidence preserved may a `NOT RUN` be changed to `PASS`.

## 2026-08-11 — Local production-mode full chain

- Environment: final production Docker images; fresh temporary PostgreSQL/Redis volumes; production config validation enabled; Cloudflare Turnstile official test key.
- Protocol: real ALE encryption + HMAC + nonce + Protobuf, requests going through a temporary local Caddy to the API.
- Result: **PASS (engineering smoke, not UAT)**
- Coverage:
  - Whitelisted registration, login, refresh and logout;
  - Created asset, liability, income and expense accounts;
  - Created income, expense and transfer transactions;
  - Updated an expense from USD 50 to USD 60;
  - Deleted the USD 25 transfer and confirmed it no longer appears in the ledger list;
  - Verified asset balance was exactly USD 1140.000000000;
  - Dashboard balance trend requests;
  - API `ready`; production log error and sensitive-pattern scans.
- Cleanup: temporary containers, networks, PostgreSQL/Redis data volumes, env files and the protocol client were removed; no smoke data retained.
- Not covered: cross-user authorization, failure-injection rollback, concurrent locks/deadlocks, real Turnstile domain, DNS/HTTPS, VPS restart, browser CAPTCHA interaction and all CORE GATE cases.

## 2026-08-12 — Automated UAT startup baseline

- Environment: `docker-compose.uat.yml` local UAT stack; PostgreSQL, Redis, RabbitMQ, API, Web and Caddy all healthy.
- Entry point: the official UAT HTTPS entry uses a Caddy internal CA; the automation browser did not bypass certificate warnings — instead a temporary HTTP proxy bound only to `127.0.0.1:8080` connected to the same UAT containers.
- Result: **PASS (startup smoke, not full UAT)**
- Coverage:
  - `/v1/health/live` returned HTTP 200 with `{"status":"alive"}`;
  - `/v1/health/ready` returned HTTP 200 with `{"status":"ready"}`;
  - Login and registration pages completed client-side rendering with no console errors or warnings;
  - Empty login fields were blocked by browser required-field constraints;
  - An invalid registration email was blocked by the browser email-format constraint;
  - Password and confirm-password had a minimum-length-8 client-side constraint.
- Ongoing execution: a UAT heartbeat automation for the current task has been created, continuing every 30 minutes to run safe CORE REGRESSION / CORE GATE cases and update evidence.
- Not covered: this record changes no UAT case status; login/registration submission, CAPTCHA, refresh tokens, accounts, transactions, Dashboard, security and concurrency gates still await later batches.

## 2026-08-14 — Production origin direct-connection verification

- Time: 10:57 CST on 2026-08-14.
- Target: bypassed Cloudflare and connected directly to `144.34.237.205` using the `gaap.cc` TLS SNI/Host header.
- Result: **PASS (confirmed by the release owner)**.
- Confirmed passing:
  - Requests truly reached the origin;
  - Origin TLS certificate;
  - HTTP automatically redirected to HTTPS;
  - Web and Caddy routing;
  - API `/api/v1/health/ready`;
  - Origin security response headers.
- Not covered: this entry only closes out the origin direct-connection gate; production login, accounts, transactions, Dashboard, refresh, logout, RabbitMQ re-checks and real-data reconciliation still need to be run separately.

## 2026-08-14 — Production business smoke entry-point fault & recovery

- Time: 10:58 CST on 2026-08-14.
- Result: **RESOLVED; the business smoke continued**.
- Public `https://gaap.cc/login` returned HTTP 525 from both browser and `curl`; Cloudflare reported
  `SSL handshake failed` / `Host Error`, with Ray IDs `a2acb279cbb8d29b` and
  `a2acb2cb2c4b85d7-NRT`.
- At the same moment, direct connection to `/login` on `144.34.237.205` using the `gaap.cc` SNI/Host header returned
  HTTP 200 with HTML, proving the Web/Caddy origin itself was available.
- Root cause: a leftover historical Origin Rule in Cloudflare that incorrectly forwarded `gaap.cc` to
  port `8081` on the VPS.
- Handling: deleted the stale Origin Rule and kept the Cloudflare orange cloud enabled; reopening public
  `https://gaap.cc/login` restored the GAAP Cloud login page.
- No logins or business writes were performed during the outage.

## 2026-08-14 — Production test user reset

- Target email: `windane@gmail.com` (confirmed by the release owner as a production test user and approved for deletion).
- Pre-delete user ID: `517a7171-45e8-4f83-90b2-46c6910c2ae9`; counts of accounts, transactions, tasks,
  Dashboard snapshots and OAuth linkage records were all 0.
- Operation: deleted inside a transaction with both user ID and email as dual conditions; the result was `DELETE 1` and committed successfully.
- Post-delete verification: users for that email = 0, Redis session/cache keys containing the old user ID = 0,
  API `/v1/health/ready` still returned `{"status":"ready"}`.
- Next step: re-register with the same whitelisted email, then continue the production business smoke.

## 2026-08-14 — Production business smoke & final reconciliation

- Time: 11:52–12:02 CST on 2026-08-14.
- User: `windane@gmail.com`; after re-registration the user ID is
  `e5bc892b-8498-4ecb-9d89-3d86b036194b`.
- Result: **PASS**.
- Auth: whitelisted re-registration succeeded and went straight into the Dashboard; after a page reload, session and data persisted;
  after logout it returned to `/login`, and Redis ALE keys for that session = 0.
- Accounts: created Asset `SMOKE-20260814-Cash` USD 1,000, Liability
  `SMOKE-20260814-Card` USD 200, Income `SMOKE-20260814-Income`, and Expense
  `SMOKE-20260814-Expense`.
- Transactions: created Income→Cash USD 300, Cash→Expense USD 50, and Cash→Card USD 25;
  updated the expense to USD 60 and then deleted the USD 25 transfer — the transaction list no longer returned the deleted transfer.
- Final account balances: Cash `1240.000000000`, Card `200.000000000`, Income
  `-300.000000000`, Expense `60.000000000`; Dashboard showed assets USD 1,240,
  liabilities USD 200, net worth USD 1,040, monthly income USD 300 and monthly expense USD 60.
- Enforced read-only reconciliation: `passed=true`, `accountsChecked=6`, `transactionsChecked=4`,
  `differences=[]`, `issues=[]`. The 6 accounts include the 2 opening-equity accounts created automatically by the system,
  and the 4 valid transactions include 2 opening balances, 1 income and 1 expense.
- RabbitMQ: both `gaap.tasks` and `gaap.dashboard` had 1 consumer each,
  with `messages_ready=0` and `messages_unacknowledged=0`.
- Server logs: no ERROR/WARN/PANIC/FATAL in API/Web within the smoke time window; an exact HTTP-status scan found no 5xx. A 401 for old-password login and a 403 for duplicate registration before deleting the old test user were explained, expected rejections.
- Browser console: no errors; observed non-blocking warnings about Dashboard chart initialization container size of `-1` and dialogs missing `Description/aria-describedby`, recorded as DEF-025 and DEF-026 respectively.
- Date semantics: the new-entry form accepts hours/minutes/seconds, but after the API returns date-only values, transaction lists and edit forms uniformly display 08:00 in the Shanghai timezone; this does not affect this round's day-based accounting and Dashboard acceptance criteria, recorded as non-blocking DEF-027.

## 2026-08-14 — Final GO decision

- Time: release decision confirmed at 12:15 CST on 2026-08-14; doc commits, push and PR checks completed by 12:22 CST. The morning task finished its wrap-up after 12:00 noon and is recorded as completed late (past due).
- Conclusion: **GO (invite-only Beta)**.
- Basis: origin and public entry points, production business smoke, RabbitMQ, read-only ledger reconciliation, logout session invalidation and server log gates all passed, with no unresolved Beta P0/P1 defects.
- Waivers: the release owner explicitly confirmed that this round does not require a production backup, an independent restore drill or daily backups; these three items are recorded as `WAIVED / ACCEPTED RISK`, not PASS, and no longer block this release.
- Accepted risks: on database failure there is no verifiable production restore point and restoring the latest business data is not guaranteed; application images can still be rolled back, but a database failure must first stop writes and preserve the scene.
- Post-release obligations: observe for at least 2 hours with continuous monitoring of 5xx, ALE/refresh, RabbitMQ, database lock waits and ledger reconciliation.

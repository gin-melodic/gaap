# GAAP TODO

## Status (updated 2026-09-03)

The invite-only Beta is **released**. The release owner gave the final GO at 12:15 CST on 2026-08-14; `gaap.cc` has been in
production since then, deployed from exact-SHA candidate images (see
[`archive/beta-2026-08-14/release-beta-2026-08-14.md`](archive/beta-2026-08-14/release-beta-2026-08-14.md) and the run evidence under [`archive/beta-2026-08-14/runs/`](archive/beta-2026-08-14/runs/)).

## Open — post-Beta follow-ups (non-blocking for this release)

1. **DEF-025 / P2**: Dashboard chart containers briefly emit `width(-1)` / `height(-1)` console warnings on initialization and reloads;
   charts render normally afterwards. Status: OPEN / NON-BLOCKING — schedule a fix in the post-Beta maintenance round.
2. **DEF-026 / P2**: New-account and new/edit/delete transaction dialogs lack `Description` / `aria-describedby`, causing persistent
   browser console warnings. Status: OPEN / NON-BLOCKING — schedule an accessibility pass together with DEF-025.
3. **DEF-027 / P2**: Transaction form accepts `datetime-local` but the API returns date-only values, so lists and edit forms uniformly
   display 08:00 in the Shanghai timezone and entered hours/minutes/seconds are lost. Status: OPEN — first decide between keeping
   date-only semantics or retaining time end-to-end (schema + ALE payload + i18n strings), then implement with boundary tests.
4. **DEF-017 / P0 — RESOLVED (2026-09-03)**: The read-only reconciler now runs as a startup gate (`boot.StartupReconcile`); production boot exits non-zero on any discrepancy or database error unless `GAAP_STARTUP_RECONCILIATION=warn|off`, non-production logs and continues. See [`release-beta-060903/def-017-startup-reconciliation.md`](release-beta-060903/def-017-startup-reconciliation.md).
5. **Waived backup gates (WAIVED / ACCEPTED RISK for this Beta)**: Production backups, an independent restore drill and daily backups
   were removed from the Beta release gate. Before GA they must be restored to the gate: schedule `scripts/production/backup-postgres.sh`
   as a daily job on the VPS, verify retention (>= 7 days), run one independent restore drill with
   `scripts/production/restore-postgres.sh`, and record evidence in this file. Until then a database failure has no verifiable production
   restore point — stop writes and preserve the scene first (see `docs/production-runbook.md`).

## Next release scope — 38 DEFERRED cases

All deferred test cases remain NOT RUN / DEFERRED and live exclusively in [`uat/deferred.md`](uat/deferred.md). When planning the round
after Beta, they map to these feature workstreams:

- Authentication & 2FA (7 cases): TOTP setup/enabling at login; password change.
- Accounts (6 cases): Pro account groups and sub-accounts, multi-level nested accounts, migration-delete for accounts that have transactions.
- Dashboard, Settings & User (10 cases): currency and theme management, user profile changes, converted valuations / exchange rates.
- Data & Tasks (15 cases): task center and data import/export; RabbitMQ remains a core dependency of the Dashboard refresh chain even while these are deferred.

## Closed — 2026-08-14 Beta release wrap-up (carried over from the night of 8/13)

All items below were completed before or at the GO decision on 2026-08-14; details and evidence remain in
`archive/beta-2026-08-14/release-beta-2026-08-14.md`, `docs/production-runbook.md` and `archive/beta-2026-08-14/runs/`.

1. **Done**: `UAT-20260813-BETA-RC-01` completed 82/82 Beta cases, 0 FAIL and 0 NOT RUN;
   DEF-019 UI bypass, ALE attacks, concurrency, historical trends and dependency recovery all passed.
2. **Done**: Final read-only reconciliation checked 142 accounts and 62 transactions, with 0 discrepancies and integrity anomalies.
3. **Done**: Release branches and draft PRs across the three repositories; API/Web CI passed; candidate images were published by exact SHA
   and deployed to the VPS via their `linux/amd64` digest.
4. **Done**: The 5 VPS migrations, container health, both RabbitMQ consumers, dependency restart recovery and read-only reconciliation on the empty production database all passed; root PR CI passed.
5. **Done**: Cloudflare DNS, Caddy HTTPS/security headers, real Turnstile and whitelisted production registration;
   orange cloud enabled with normal public access, and Caddyfile permissions restored.
6. **Done**: Origin verification bypassing Cloudflare via direct connection to `144.34.237.205` passed;
   direct-connection confirmation, TLS certificate, HTTP→HTTPS, Web/Caddy routing, API ready status and security headers all PASS.
7. **Done**: The 525 error caused by Cloudflare's legacy Origin Rule is resolved; production re-registration, login,
   accounts, income/expense/transfer, update, delete, Dashboard, refresh and logout smoke checks all passed.
   Both RabbitMQ queues have one consumer each with no backlog; the production read-only reconciliation checked 6 accounts and 4 transactions,
   `passed=true`, with no discrepancies or integrity issues; the final log scan found no unexplained errors or 5xx responses.
8. **Done (overdue wrap-up)**: The release owner confirmed the final GO at 12:15 CST on 2026-08-14;
   by 12:22 CST, production evidence had been updated, docs committed and pushed, PR checks passed, and the root, API and Web
   workspaces were confirmed clean.
9. **WAIVED / ACCEPTED RISK**: The release owner confirmed at 12:15 CST on 2026-08-14 that production backups, an independent restore drill and daily backups are not required for this round; these three items are removed from the Beta release gate and are not recorded as PASS (carried forward as open item 5 above).

# GAAP TODO

## Status (updated 2026-09-04)

The invite-only Beta is **released**. The release owner gave the final GO at 12:15 CST on 2026-08-14; `gaap.cc` has been in
production since then, deployed from exact-SHA candidate images (see
[`archive/beta-2026-08-14/release-beta-2026-08-14.md`](archive/beta-2026-08-14/release-beta-2026-08-14.md) and the run evidence under [`archive/beta-2026-08-14/runs/`](archive/beta-2026-08-14/runs/)).
The post-Beta maintenance round on 2026-09-03 closed DEF-025, DEF-026 and DEF-027 (records under
[`release-beta-060903/`](release-beta-060903/)); only the waived backup gates remain open below. On 2026-09-04 the P2 fixes were re-verified end-to-end on a clean local UAT (P2 mock + p2-round all green, including an
end-date boundary fix in `gaap-api`); security-gate/full-gate need one quiet-network re-run — see
[`release-beta-060903/local-uat-verification.md`](release-beta-060903/local-uat-verification.md).

## Open — post-Beta follow-ups (non-blocking for this release)

1. **DEF-025 / P2 — RESOLVED (2026-09-03)**: Dashboard chart containers briefly emitted `width(-1)` / `height(-1)` console warnings on
   initialization and reloads; charts render normally afterwards. Fixed by measuring the container ourselves and mounting recharts only
   with explicit pixel dimensions, plus a regression test that fails on the pre-fix code (see
   [`release-beta-060903/def-025-chart-size-warning.md`](release-beta-060903/def-025-chart-size-warning.md)).
2. **DEF-026 / P2 — RESOLVED (2026-09-03)**: New-account and new/edit transaction dialogs lacked `Description` / `aria-describedby`,
   causing persistent browser console warnings. Localized dialog descriptions were added to all affected dialogs in en, ja, zh-CN and
   zh-TW; the delete confirmations already had them (see
   [`release-beta-060903/def-026-dialog-a11y-descriptions.md`](release-beta-060903/def-026-dialog-a11y-descriptions.md)).
3. **DEF-027 / P2 — RESOLVED (2026-09-03)**: Transaction form accepts `datetime-local` but the API returned date-only values, so lists
   and edit forms uniformly displayed 08:00 in the Shanghai timezone and entered hours/minutes/seconds were lost. Decision: retain full
   date/time end-to-end — no schema change needed (`transactions.date` is already `timestamptz`); responses now serialize RFC3339
   timestamps, with boundary tests on both sides (see
   [`release-beta-060903/def-027-transaction-datetime-semantics.md`](release-beta-060903/def-027-transaction-datetime-semantics.md)).
4. **DEF-017 / P0 — RESOLVED (2026-09-03)**: The read-only reconciler now runs as a startup gate (`boot.StartupReconcile`); production boot exits non-zero on any discrepancy or database error unless `GAAP_STARTUP_RECONCILIATION=warn|off`, non-production logs and continues. See [`release-beta-060903/def-017-startup-reconciliation.md`](release-beta-060903/def-017-startup-reconciliation.md).
5. **Waived backup gates (WAIVED / ACCEPTED RISK for this Beta)**: Production backups, an independent restore drill and daily backups
   were removed from the Beta release gate. Before GA they must be restored to the gate: schedule `scripts/production/backup-postgres.sh`
   as a daily job on the VPS, verify retention (>= 7 days), run one independent restore drill with
   `scripts/production/restore-postgres.sh`, and record evidence in this file. Until then a database failure has no verifiable production
   restore point — stop writes and preserve the scene first (see `docs/production-runbook.md`).
6. **Local UAT regression re-run (2026-09-04)**: security-gate (7/7) and full-gate (best 62/69, FAILs all envelope-level:
   ALE `Unable to verify secure API response` / cascaded session / CONC `fetch failed`) were blocked by Docker Desktop VM network
   flake; no assertion failure touches dates or formatting. Re-run both after a fresh reset in a quiet window and append the
   evidence to [`release-beta-060903/local-uat-verification.md`](release-beta-060903/local-uat-verification.md).

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

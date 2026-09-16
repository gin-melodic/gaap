# Local UAT verification — 2026-09-04

Re-ran the local UAT stack (`.env.uat`, `docker-compose.uat.yml`) end-to-end to verify the P2 post-Beta
fixes on a clean database, plus the broader regression gates.

## Fixes under verification

- DEF-027 RFC3339 serialization (`gaap-api/internal/logic/transaction/transaction.go`): transaction list/create/update
  responses now carry full second precision; verified by `src/uat/p2-round.test.ts`.
- DEF-027 end-date boundary (same file, new helper `endDateFilter`, test
  `gaap-api/internal/logic/transaction/end_date_filter_test.go`): a plain calendar `EndDate` becomes an exclusive
  next-midnight boundary (`date < 'YYYY-MM-DD 00:00:00'`) so end-of-day rows are no longer excluded; timestamps keep
  inclusive `<=`. DB check on the same window returned 3 rows with the old predicate and 4 with the new one.

## Evidence (2026-09-04, local UAT, Asia/Shanghai)

- `gaap-api` unit tests: `go build ./...` clean; `go test ./internal/logic/transaction/ ./internal/controller/transaction/` all pass.
- `src/uat/p2-round.test.ts`: **1 passed** — RFC3339 round-trip, 23:59:59 end-of-day precision and the list window
  `[2026-09-01, 2026-09-04]` returning all 4 fixtures including the `2026-09-04 08:07:06` midday row.
- Playwright mock (`gaap-web/scripts/local-uat-p2-browser.mjs`, session from `src/uat/browser-session.test.ts`):

```text
GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF025-DASH-CHART","status":"PASS","detail":"surfaces=2, sizeWarnings=[]"}
GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF026-ACCOUNTS-DIALOG","status":"PASS","detail":"description=\"Create a new account with its type, opening date and initial balance.\""}
GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF026-TXN-DIALOG","status":"PASS","detail":"description=\"Record an income, expense or transfer; the transaction time is kept with second precision.\""}
[resp] 200 /api/v1/transaction/create-transaction
GAAP_UAT_BROWSER_CONFIRM_TOASTS=["Transaction created successfully"]
GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF027-TXN-SECONDS","status":"PASS","detail":"list displays wall-clock time with seconds (p2-browser-def027)"}
```

  The DEF-027 gate now asserts a run-unique note (`p2-browser-def027`) instead of the shared timestamp, and logs API
  status + toasts around Confirm so stale rows can no longer produce false passes. The script also tolerates duplicate
  same-name accounts (strict-mode-safe option picking).
- List page probe after create: all `/api/v1/*` responses 200, zero console errors, rows rendered with wall-clock
  seconds (`2026-09-04 08:07:06`, `2026-09-03 23:59:59`).

## Regression gates (environment-blocked)

- `security-gate.test.ts`: all 7 tests failed with ALE envelope-level errors (`Unable to verify secure API response` /
  per-test 5s timeouts) across every attempt today.
- `full-gate.test.ts`: best run was 62 PASS / 7 FAIL (of 69 gate lines); every failure is envelope-level
  (`Unable to verify secure API response`, cascaded `accessToken` undefined, CONC `fetch failed`) — same class as the
  Sep-3 pre-change run whose only failures were TC-EDGE-CONC-001/002 `fetch failed`. No assertion failure mentions dates,
  formatting or filters.
- Meanwhile `browser-session.test.ts`, `p2-round.test.ts` and Playwright runs stayed green repeatedly in the same window,
  so this is assessed as Docker Desktop VM network flake, not a regression from today's two API changes.
- **Follow-up**: re-run security-gate + full-gate once in a quiet-network window (fresh reset first) and record results here.

## Notes

- UAT `gaap-api:uat-local` was rebuilt on 2026-09-04 with both DEF-027 fixes; earlier same-day runs had silently reused
  the pre-fix image because a `| tail` pipe masked the build failure — build exit codes are checked now.
- Dev stack left untouched; its image will pick up the fixes on next `docker compose build`.
- Scratch probes (`uat-dump-rows.tmp.mjs`, `uat-list-probe.tmp.mjs`, `uat-confirm-probe.tmp.mjs`) removed after use.
  Repo remains uncommitted per local-UAT workflow.

## Re-run 2026-09-04 (DEF-028 fix, post-rebuild)

Context: while re-verifying the P2 round, an end-to-end trend lifecycle probe on local UAT exposed DEF-028 —
`calculateBalanceTrend` bucketed transactions by UTC calendar day instead of the server-local (+08) day, so a
transaction edited from 2026-08-08 to 2026-08-09 never re-converged in the trend series. Fixed with a one-line
zone-aware bucketing change plus regression unit test (see [`def-028-trend-local-calendar-bucketing.md`](def-028-trend-local-calendar-bucketing.md)).

Environment prep for this round: UAT `gaap-api` rebuilt with the fix. The rebuild surfaced two environment
issues, both worked around without repo changes except pinning `dlv@v1.23.1` in `gaap-api/Dockerfile` (dlv v1.27.x
requires Go >= 1.25 and broke every build): Docker Hub IPv6 resets to `auth.docker.io` during BuildKit frontend
fetch, and corrupted alpine CDN package downloads inside the builder (rebuilt via classic builder with an Aliyun
apk mirror copy of the Dockerfile). UAT user passwords for A/B were reset directly in Postgres (bcrypt) since the
stack had been freshly re-provisioned.

- `security-gate.test.ts` (`RUN_GAAP_UAT_SECURITY=1`, user A): **7/7 PASS**, exit 0 — first green run after the
  earlier envelope-blocked window.
- `full-gate.test.ts`: two consecutive runs, both **78 unique gates PASS / 6 FAIL**. The same six gates failed in
  both runs and all failures are envelope-level: TC-AUTH-REG-001, TC-EDGE-AUTH-003/004, TC-ACCT-LIST-003
  (`Unable to verify secure API response`) plus cascaded session losses (TC-DASH-SUMMARY-002, TC-EDGE-SEC-003,
  `accessToken` undefined). **No date/formatting/filter assertion failed.** Notably `TC-DASH-TREND-001`,
  `TC-DASH-SUMMARY-001`, `TC-DASH-MONTHLY-001` and every transaction/account/concurrency gate passed.
- Targeted trend lifecycle probe (create 2026-08-08 → edit to 2026-08-09 → delete) on the fixed build converged on
  the first read after each mutation: baseline 100 → 97 from 08-08 → **100 for 08-08 / 97 for 08-09** → back to 100.
  Pre-fix this sequence never re-converged after the edit.

Remaining: a fully clean full-gate (0 envelope flakes) still needs a quieter network window; the four flaky gates
fail intermittently on ALE response verification through the local Caddy path and reproduce independently of today's
changes.

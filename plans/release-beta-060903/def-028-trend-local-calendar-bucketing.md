# DEF-028 — Balance trend buckets transactions by UTC day instead of the server-local calendar day

**Date:** 2026-09-04
**Severity:** P2 (post-Beta follow-up; surfaced while re-verifying the P2 round on local UAT)
**Status:** RESOLVED

## Symptom

Dashboard "Balance Trend" did not converge after editing a transaction's date. Reproduced end-to-end on
local UAT with user `uat-20260813-a@gaap.local`:

1. Asset opened at 100 CNY (2026-08-01). Baseline trend: every day = 100.
2. Create an expense of 3 dated **2026-08-08** → trend from 2026-08-08 onward = 97 (correct).
3. Edit the same transaction to date it **2026-08-09**. `GET` immediately returned
   `"date":"2026-08-09T00:00:00+08:00"`, but the trend kept reporting 97 for 2026-08-08 indefinitely —
   it never flipped back to 100 even after repeated reads (snapshot invalidation + worker rebuild each
   produced the same wrong series).
4. Deleting the transaction restored the baseline, proving the derivation input was correct and only the
   date bucketing was wrong.

## Root cause

`calculateBalanceTrend` walks back day by day using **server-local calendar dates** (the walk cursor is a
local `time.Time`, see `resolveTrendDateRange` / TZ=Asia/Shanghai on UAT and production), but it grouped
transaction rows with:

```go
dateStr := t.Date.Layout("2006-01-02")   // snapshot.go, pre-fix
```

Transaction dates are stored as instants (`timestamptz`). The API renders/creates them at local midnight —
a transaction entered for 2026-08-09 (+08) is the instant **2026-08-08T16:00Z**. Postgres scans that back
as a UTC-location `time.Time`, so `Layout("2006-01-02")` produced **"2026-08-08"**: the expense was always
bucketed into the *previous UTC day* and applied one local day too early. Moving its date from 08-08 to
08-09 moved the instant from `...07T16:00Z` to `...08T16:00Z`, which still lands in a "wrong but earlier"
UTC bucket — hence the trend never converged after an edit. The pre-existing unit test passed because it
built fixtures with UTC-zone times where UTC day == walk day.

## Fix (gaap-api)

- `internal/logic/dashboard/snapshot.go`: group transactions by the **walk's calendar zone**:
  `t.Date.In(endDate.Location()).Format("2006-01-02")` (`endDate` carries the server-local location from
  `resolveTrendDateRange`). One-line semantic change; no schema or API shape changes.
- `internal/logic/dashboard/balance_trend_test.go`:
  - New regression test `TestCalculateBalanceTrendDBScannedTransactionUsesLocalCalendarDate` emulates a
    Postgres-scanned row (UTC-location time.Time at the local-midnight instant) and asserts it is applied
    on its server-local date. Fails on the pre-fix code.
  - The two legacy trend tests now pin their walk window to the same +08 zone as production instead of UTC,
    so fixtures stay consistent with how stored instants are interpreted.

## Build note (unrelated latent breakage found while rebuilding UAT)

- `gaap-api/Dockerfile` installed `github.com/go-delve/delve/cmd/dlv@latest`; dlv v1.27.1 now requires
  Go >= 1.25 and broke every build of the dev stage (builder runs go 1.24, GOTOOLCHAIN=local). Pinned to
  `dlv@v1.23.1`.
- Local rebuilds also hit transient Docker Hub IPv6 resets (`auth.docker.io`) and corrupted alpine CDN
  package downloads; UAT image was rebuilt with the classic builder using an Aliyun apk mirror copy of the
  Dockerfile (no repo change for that part).

## Verification

- `go test ./internal/logic/dashboard/` — all green, including the new regression test.
- End-to-end probe on local UAT after deploying the fixed image: baseline 100 → create(2026-08-08) gives
  97 from 08-08 onward → edit to 2026-08-09 immediately yields **100 for 08-08 / 97 for 08-09** → delete
  restores baseline on both days. Converged on the first read after each mutation (pre-fix: never converged).

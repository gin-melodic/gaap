# DEF-017: Wire read-only ledger reconciliation into API startup

**Status**: RESOLVED (2026-09-03) — implemented and verified.

## Context

DEF-017 was tracked as P0 "mitigated, not resolved": the dead `performBalanceSync` / `SyncBalances`
auto-repairer (`gaap-api/internal/boot/sync.go`) is not a suitable production auto-repairer, so ledger
correctness relied on read-only reconciliation (`reconciliation.Run`, PostgreSQL
`REPEATABLE READ, READ ONLY`) being run manually through the standalone `./reconcile` release gate.
This change wires that same reconciler into API startup so discrepancies block or alert at boot instead
of surfacing later under load.

## Decisions

- **Fail closed in production**: default mode is `block` when `boot.IsProduction()`, otherwise `warn`.
  In blocking mode a database error or any discrepancy/issue makes the process exit non-zero; with Docker
  `restart: unless-stopped` (single-instance production) the API crash-loops until an operator fixes the
  ledger. Non-production logs at Error level and continues serving.
- **Operator escape hatch**: new env var `GAAP_STARTUP_RECONCILIATION` = `block` | `warn` | `off`.
  `warn` logs the full report JSON at Error and continues; `off` skips with no database access (Info log).
  Unknown values fail closed in production (consistent with `boot.ValidateProductionConfig`) and fall back
  to `warn` elsewhere. No new env var is needed in dev/UAT compose files — the defaults cover them.
- **No auto-repair**: startup reconciliation stays strictly read-only (the reconciler enforces the
  read-only transaction itself); manual repair remains "stop writes, preserve the scene" per the runbook.
  No schema migration required.
- **Dead sync code untouched**: `performBalanceSync` / `SyncBalances` in `gaap-api/internal/boot/sync.go`
  and the standalone `./reconcile` binary (exit code 2 release gate) are unchanged.

## Implementation

- New `gaap-api/internal/boot/startup_reconciliation.go`: `StartupReconcile(ctx context.Context) error`.
  Resolves the mode from the env var with environment-based defaults; `off` short-circuits before any DB
  access; otherwise calls `reconciliation.Run(ctx)` and:
  - on DB error returns the wrapped error in block mode, logs Error and returns nil in warn mode;
  - on a failed report always logs the full report JSON at Error, and in block mode additionally returns an
    error summarizing difference/issue counts that points to `GAAP_STARTUP_RECONCILIATION=warn` or `off`;
  - on pass logs Info with the checked account/transaction counts.
- `gaap-api/internal/cmd/cmd.go`: calls `boot.StartupReconcile(ctx)` immediately after `boot.InitALE(ctx)`,
  before dashboard warmup; a non-nil error returns from `Main` so the HTTP server never starts.

## Test evidence

Verification commands (all clean):

```sh
cd gaap-api && go build ./...
go vet ./internal/boot/... ./internal/cmd/...
go test ./internal/boot/... ./internal/logic/reconciliation/...   # ok gaap-api/internal/boot, ok gaap-api/internal/logic/reconciliation
```

New `gaap-api/internal/boot/startup_reconciliation_test.go` uses the existing sqlmock pattern from
`reconciliation_test.go` (`testutil.InitMockDB`, `t.Setenv` for mode control):

- Empty ledger passes with all read-only transaction expectations met (Begin, SET isolation, both SELECTs, Commit).
- Boundary case per the AGENTS.md financial boundary rule: an account/transaction pair differing by exactly
  **1 nano** (`balance_nanos = 999_999_999` vs a 1-unit opening balance) → non-nil error in production; nil in non-production/warn mode.
- Production + `=warn` with the same discrepancy → nil (boot continues, report logged).
- Production + `=off` → no database queries issued at all; expectations met with none pending.
- Database failure on the accounts query → error in block mode; Error log and nil in warn mode (rollback expectation met).
- Unknown override value: fail-closed error in production before any DB access; non-production falls back to `warn` and continues.

## Local deployment verification (live, 2026-09-03)

Deployed on the local dev stack (`./start-dev.sh start middleware`, API from `gaap-api/tmp/main` on :8000)
with a seeded ledger fixture: two accounts (`Recon-Equity` type 5 / `Recon-Cash` type 1, CNY) and one
opening-balance transaction (type 4), balanced at 100 units.

- **Balanced boot**: `[INFO] Startup reconciliation passed: 2 account(s) and 1 transaction(s) checked`;
  `/v1/health/live` and `/ready` both green while serving.
- **Exactly 1 nano discrepancy** (`accounts.balance_nanos` 0 to 1 on `Recon-Cash`): the running dev instance
  (non-production default `warn`) logged `[ERRO] Startup ledger reconciliation failed: {... "difference":"0.000000001" ...}`
  and kept serving; `/v1/health/live` stayed alive.
- **Block mode, same 1 nano discrepancy**: `GAAP_STARTUP_RECONCILIATION=block ./tmp/main` exited with code 1
  before the HTTP server started, fatal message: `startup ledger reconciliation found 1 balance difference(s)
  and 0 issue(s); set GAAP_STARTUP_RECONCILIATION=warn or off to override the gate`.
- **Scene restored** (`balance_nanos` back to 0): next boot logged the passed line again; health green.
- **Full mock suite**: `cd gaap-api && go test ./...` — all 15 test packages `ok`, exit code 0 (full sqlmock
  run, not just boot/reconciliation).

## Follow-ups / notes

- Documented in `docs/production-runbook.md` under Deployment & Verification: the boot gate behavior, the
  `GAAP_STARTUP_RECONCILIATION=warn|off` recovery procedure for `.env.production`, and the stop-writes /
  preserve-the-scene rule before touching balances.
- A failing production boot intentionally keeps crash-looping until an operator intervenes; there is no
  automatic fallback to a mutable repair path.

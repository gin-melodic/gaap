# Automation & Reconciliation Run Records

## 2026-08-13 — Ledger and Dashboard Release Gate

- Environment: `gaap.local` UAT Compose, PostgreSQL 18.
- Read-only reconciliation command:
  `docker compose --env-file .env.uat -f docker-compose.uat.yml run --rm --no-deps gaap-api ./reconcile`
- Read-only guarantee: the command enables PostgreSQL `REPEATABLE READ, READ ONLY` before reading and reads accounts and transactions from the same snapshot; it only reports differences and never performs balance repair.
- Reconciliation result: PASS; 9 valid accounts, 5 valid transactions, 0 balance discrepancies, 0 integrity anomalies.
- Automation result: `go test ./...` PASS.
- Covered scenarios: assets, liabilities, income, expenses, equity, opening balances, transfers, a 1 nano difference, cross-user,
  cross-currency, fixed UUID order `SELECT FOR UPDATE`, transaction rollback when the second account update fails, and the 30-day Dashboard end-of-day balance after creating, updating or deleting historical-date transactions.
- Browser read-only check: existing 2026-08-02, 08-05 and 08-06 historical transactions display correctly and the 30-day Dashboard trend loads normally; this batch added no new UAT data and modified or deleted none.

## 2026-08-13 — UAT-20260813-BETA-RC-01 Final Gate

- Protocol UAT: all 76 formal cases plus 1 extended check PASS.
- ALE raw security gate: 7/7 PASS.
- Final read-only reconciliation: 142 accounts, 62 transactions, 0 balance discrepancies, 0 integrity anomalies.
- API: 152 Go tests passed; `go build ./...` passed.
- Web: 74 standard Vitest tests passed; ESLint, TypeScript and the production Next.js build all passed;
  `npm audit --audit-level=low` reported 0 issues.
- Full execution context plus browser/fault-recovery evidence is in
  [`runs/2026-08-13-beta-rc-01.md`](runs/2026-08-13-beta-rc-01.md).

# GAAP Beta UAT

Main release plan: [GAAP Invite-Only Beta Release Plan](../release-beta-2026-08-14.md).

The Excel workbook is deprecated. This directory is the single source of truth for UAT status.

## Current Baseline

- 2026-08-12 manual UAT batch: **PASS** (confirmed by the user on 2026-08-13). Because no per-case checklist or evidence was provided, this confirmation does not bulk-overwrite the per-case statistics below yet; see `manual-runs.md` for details.

- Total cases: 120
- Passed: 82
- Failed runs: 0
- Not run: 38 (all DEFERRED)
- Beta case count for this round: 82 (8 CORE REGRESSION + 74 CORE GATE)
- Core gates still pending execution for this Beta: 0
- Non-Beta deferred cases: 38, consolidated into `deferred.md`
- The fund-flow test sheet was originally blank; no cases were generated from it.

Full-protocol, browser, fault-recovery and reconciliation evidence from 2026-08-13 is in
[`UAT-20260813-BETA-RC-01`](runs/2026-08-13-beta-rc-01.md). The six Beta module files were re-counted to
82 items; the earlier 80/67 counting basis had missed two token security cases, and no omissions in the original workbook were found.

## Status Rules

- `PASS`: the case was actually executed under UAT and passed; it must continue to be regressed.
- `FAIL`: actually executed with an unexpected result; it must be fixed and re-run.
- `NOT RUN`: not yet executed; it cannot be interpreted as either pass or fail.
- `CORE GATE`: must be executed and passed before this Beta release.
- `DEFERRED`: the feature is not part of this Beta; keep NOT RUN.

Module documents only store cases for this Beta round. All DEFERRED cases live exclusively in `deferred.md` to avoid them being accidentally selected while running
Beta UAT, and to avoid maintaining the same case in multiple files.

## Files

- [Authentication](authentication.md)
- [Accounts](accounts.md)
- [Transactions](transactions.md)
- [Dashboard, Settings & User](dashboard-and-user.md)
- [Health Checks](data-tasks-health.md)
- [Security, Integrity & Concurrency](security-integrity-concurrency.md)
- [Non-Beta Deferred Test Cases](deferred.md)
- [Defect List](defects.md)
- [Automated Smoke Records](smoke-runs.md)
- [Automation & Reconciliation Run Records](automated-runs.md)
- [Manual UAT Batch Records](manual-runs.md)
- [2026-08-13 Beta RC Full-Closure Evidence](runs/2026-08-13-beta-rc-01.md)

# Manual UAT Batch Records

This file records the conclusions of manual UAT batches. Per-case status remains based on each module document's "Execution Status" and execution evidence as authoritative.

## 2026-08-12 — Manual UAT

- Result: **PASS**.
- Confirmed at: 2026-08-13.
- Source of confirmation: the project lead confirmed "the manual UAT on 2026-08-12 passed".
- Execution environment: not provided separately; the current planned UAT baseline entry point is `https://gaap.local`.
- Case scope and per-item evidence: not supplied with the confirmation, so cases still marked `NOT RUN` were not bulk-changed to
  `PASS`. When the mapping is completed later, execution batch, environment and evidence must be recorded in the corresponding module document.

## 2026-08-13 — Beta RC Full UAT

- Execution batch: `UAT-20260813-BETA-RC-01`.
- Result: **82/82 Beta cases PASS, 0 FAIL, 0 NOT RUN**.
- Method: real Chrome page flows, the real protobuf + ALE HTTPS protocol, raw ALE attack requests,
  Compose fault injection and PostgreSQL read-only reconciliation.
- Full evidence: [`runs/2026-08-13-beta-rc-01.md`](runs/2026-08-13-beta-rc-01.md).

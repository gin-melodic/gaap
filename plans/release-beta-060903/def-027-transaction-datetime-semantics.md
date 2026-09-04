# DEF-027: Transaction form time lost — date-only API responses

**Status**: RESOLVED (2026-09-03) — implemented and verified. Semantics decision: **retain full date/time end-to-end**.

## Context

DEF-027 was tracked as P2: the transaction dialog uses a `datetime-local` input, but the API returned
date-only values (`Y-m-d`). As a result, lists and edit forms uniformly displayed 08:00 in the Shanghai
timezone (a bare `YYYY-MM-DD` string parses as UTC midnight → 08:00 local), and any hours/minutes/seconds
the user entered were lost on re-edit.

Investigation showed the storage layer already keeps full timestamps — `transactions.date` is
`timestamptz`, clients already send `YYYY-MM-DD HH:mm:ss`, and `gtime.NewFromStr` parses it into server-local
wall-clock time. The loss happened purely in response serialization:
`gaap-api/internal/controller/transaction/transaction.go` truncated every transaction date to `Y-m-d`.

## Decisions

- **Retain time end-to-end** (instead of switching the product to date-only): no schema migration is
  needed because the column and existing production rows already carry sub-day precision, the client
  form already collects seconds, and all four locale files already label the field "Transaction Time /
  取引日時 / 交易时间". Truncating on output was the only inconsistency.
- **ALE payload**: no transport-layer change required — `v1.Transaction.date` is a plain string inside
  the encrypted ALE envelope; its content now carries an RFC3339 timestamp instead of a bare date.
- Response format chosen as **RFC3339 with offset** (e.g. `2026-08-14T15:30:05+08:00`) rather than a
  naive local string, so `new Date()` in the browser parses unambiguously for users in any timezone and
  the leading `YYYY-MM-DD` prefix keeps existing string-based consumers (dashboard monthly filtering)
  working unchanged.
- **i18n**: no string rewrites were needed; only new dialog-description strings from DEF-026 touch these
  forms, plus `transactions:transaction_form_desc` states "kept with second precision".

## Implementation

- `gaap-api/internal/controller/transaction/transaction.go`: `gtimeToDateString` (Y-m-d) replaced by
  `gtimeToTimestampString`, which serializes `t.Time.Format(time.RFC3339)` and keeps the nil guard;
  used by `entityToProto`, covering list/get/create/update responses. The account controller's separate
  date helper is untouched (account opening dates remain date-only).
- Web: `getCurrentDateTime` / `formatDateForInput` / `formatDateForDisplay` were moved verbatim out of
  `gaap-web/src/components/features/Transactions.tsx` into the shared unit-testable util
  `gaap-web/src/lib/utils/date-format.ts`; display already rendered hour/minute/second, so no UI markup
  changed.

## Verification (boundary tests)

- New `gaap-api/internal/controller/transaction/transaction_date_test.go`:
  - serializer boundaries: midnight start-of-year, end-of-year 23:59:59 with seconds + offset,
    sub-second nanosecond truncation to whole seconds, year-1 zero-time boundary, UTC → `Z` rendering, nil → "";
  - client payload round-trip for the create/update parse path (`gtime.NewFromStr("YYYY-MM-DD HH:mm:ss")`):
    midnight and end-of-year values serialize back with every sub-day component intact;
  - `entityToProto` / `entitiesToProtos` preserve the exact instant through serialization.
  - `go build ./...`, `go vet` and both transaction test packages pass locally (Go 1.26.2).
- New `gaap-web/src/lib/utils/date-format.test.ts` (TZ pinned to Asia/Shanghai, production zone):
  end-of-year / start-of-year padding boundaries for form default values; RFC3339 same-zone input keeps
  seconds; UTC instant crossing the local day boundary (`16:00Z` → next-day `00:00`); legacy date-only
  payloads map to local 08:00 instead of disappearing; unparseable input returned unchanged; display
  format renders full second precision at midnight boundaries.
- Full web suite green after the change: 94 passed, 8 skipped (vitest), `tsc --noEmit` clean, ESLint clean.

## Local UAT verification (2026-09-04)

- Follow-up boundary fix landed in `gaap-api/internal/logic/transaction/transaction.go`: a plain calendar end date is now an
  exclusive next-midnight predicate (`endDateFilter`, unit-tested in
  `internal/logic/transaction/end_date_filter_test.go`), so end-of-day rows inside the filter window are no longer dropped.
- `src/uat/p2-round.test.ts`: **1 passed** — RFC3339 list round-trip, `2026-09-03 23:59:59` precision, and the
  `[2026-09-01, 2026-09-04]` window returning all 4 fixtures including the end-date-day midday row.
- Playwright mock: `GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF027-TXN-SECONDS","status":"PASS",
  "detail":"list displays wall-clock time with seconds (p2-browser-def027)"}` with
  `[resp] 200 /api/v1/transaction/create-transaction` and toast `Transaction created successfully`.

## Local UAT verification (2026-09-04)

- Follow-up boundary fix landed in `gaap-api/internal/logic/transaction/transaction.go`: a plain calendar end date is now an
  exclusive next-midnight predicate (`endDateFilter`, unit-tested in
  `internal/logic/transaction/end_date_filter_test.go`), so end-of-day rows inside the filter window are no longer dropped.
- `src/uat/p2-round.test.ts`: **1 passed** — RFC3339 list round-trip, `2026-09-03 23:59:59` precision, and the
  `[2026-09-01, 2026-09-04]` window returning all 4 fixtures including the end-date-day midday row.
- Playwright mock: `GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF027-TXN-SECONDS","status":"PASS",
  "detail":"list displays wall-clock time with seconds (p2-browser-def027)"}` with
  `[resp] 200 /api/v1/transaction/create-transaction` and toast `Transaction created successfully`.

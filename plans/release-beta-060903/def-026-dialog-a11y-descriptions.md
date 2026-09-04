# DEF-026: Dialogs missing `DialogDescription` / `aria-describedby`

**Status**: RESOLVED (2026-09-03) — implemented and verified.

## Context

DEF-026 was tracked as P2: the new-account dialog and the transaction new/edit dialogs rendered a Radix
`DialogContent` with a title but no description, producing persistent browser console warnings about a
missing accessible name (`Description or aria-describedby`) every time those dialogs opened. The
transaction delete confirmation and account delete confirmations already had descriptions; only three
dialogs were missing them (verified by auditing all `DialogContent` usages).

## Decisions

- Add visible localized `DialogDescription` text under each dialog title rather than an empty
  `sr-only` description — it doubles as useful guidance for the form below.
- All strings added to every locale namespace per project i18n rules (en, ja, zh-CN, zh-TW).

## Implementation

- `gaap-web/src/components/features/AddAccountModal.tsx`: imports and renders
  `t('accounts:add_account_desc')` under the "Add Account" title.
- `gaap-web/src/components/features/EditAccountModal.tsx`: renders `t('accounts:edit_account_desc')`
  under the "Edit Account" title (the sibling delete confirmation already had a description).
- `gaap-web/src/components/features/Transactions.tsx`: the shared new/edit transaction form dialog now
  renders `t('transactions:transaction_form_desc')`.
- New locale keys in all four languages, both namespaces:
  - `accounts.json`: `add_account_desc`, `edit_account_desc`
  - `transactions.json`: `transaction_form_desc`

## Verification

- All touched JSON locale files re-parse as valid JSON (scripted check).
- Full web suite green after the change: 94 passed, 8 skipped (vitest), `tsc --noEmit` clean, ESLint
  clean on all four modified components.

## Local UAT verification (2026-09-04)

- Playwright mock on local UAT: both dialogs carry non-empty descriptions —
  `GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF026-ACCOUNTS-DIALOG","status":"PASS"}` and
  `GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF026-TXN-DIALOG","status":"PASS"}` (see
  [`local-uat-verification.md`](local-uat-verification.md) for the full evidence lines).

## Local UAT verification (2026-09-04)

- Playwright mock on local UAT: both dialogs carry non-empty descriptions —
  `GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF026-ACCOUNTS-DIALOG","status":"PASS"}` and
  `GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF026-TXN-DIALOG","status":"PASS"}` (see
  [`local-uat-verification.md`](local-uat-verification.md) for the full evidence lines).

# Changelog

All notable GAAP Cloud releases are recorded here. **English only** — the
localized in-app copy lives in `gaap-web/src/locales/{en,zh-CN,zh-TW,ja}/changelog.json`.
Version baseline rules: see [`VERSIONING.md`](VERSIONING.md).

## [v0.0.2-beta] — Upcoming (multi-currency extension)

### Added

- Multi-currency support: per-currency standalone accounts and same-currency transactions
- Exchange rate management: daily reference-rate sync with manual overrides
- Base-currency Dashboard valuation with missing-rate reporting
- Currency management in Settings (base currency, supported currencies, rate sync)

### Fixed

- Trend chart now buckets by the local calendar day (DEF-028)
- To/From dropdowns keep each currency pair to a single currency (DEF-030)
- Settings rows and the sidebar profile shortcut are keyboard-operable (DEF-031)
- Update-profile wire payload pinned and verified end-to-end (DEF-029)

## [v0.0.1-beta] — 2026-08-14

### Added

- Invite-only Beta: whitelisted registration, login/refresh/logout with independent multi-device sessions over the ALE-encrypted protobuf channel
- Asset, liability, income and expense accounts
- Income, expense and transfer transactions, with update and delete
- Dashboard with a 30-day balance trend
- Settings: profile, appearance & themes, language preference

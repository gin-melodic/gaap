# GAAP Development Plan: 2026-08-17 to 2026-08-21

Version: 2026-08-14 planning baseline  
Capacity: one independent developer, five development days, rolling weekly  
Weekly theme: multi-currency accounts and base-currency valuation

This document records the weekly plan, confirmed product decisions, current implementation facts,
and medium- to long-term priorities agreed on 2026-08-14. Beta UAT status remains authoritative in
`plans/uat/`; this plan does not change any `NOT RUN / DEFERRED` result.

## 1. Confirmed decisions

- GAAP exists primarily to solve multi-account, multi-currency tracking and valuation. Roadmap
  priority follows that product goal rather than mechanically following deferred test-case labels.
- Standalone multi-currency accounts are available to all invited Beta users. Account groups and
  child accounts remain deferred and are not unlocked with this capability.
- Beta uses only
  [`fawazahmed0/exchange-api`](https://github.com/fawazahmed0/exchange-api) for automatic rates,
  with jsDelivr as the primary URL and Cloudflare Pages as the fallback.
- The Beta source provides daily reference rates, not tick-by-tick market data. UI copy must say
  “Daily reference rate” or “Latest reference rate,” never “Real-time rate.”
- Automatic rates are persisted server-side. Users may define persistent manual overrides; a manual
  override always takes precedence and removal restores the latest automatic rate.
- Twelve Data is not part of Beta. A later rolling release may implement `TwelveDataProvider` for
  minute-level rates as a paid-user capability, after rechecking current quotas and display licensing.
- This week does not implement cross-currency exchange transactions. Beta first supports native-
  currency accounts, same-currency bookkeeping, and base-currency valuation. Cross-currency exchange
  requires a separate dual-amount transaction model.
- Production backup work is not the immediate priority for this personal project. The 2-core, 2-GB
  VPS first receives lightweight resource and service alerts through Telegram without adding a
  Prometheus/Grafana stack.
- Development artifacts, GitHub Project titles, and issue content are written in English.

## 2. Current implementation baseline

The repository contains useful building blocks, but no complete multi-currency product path:

- `gaap-web/src/components/features/settings/CurrencySettings.tsx` already fetches
  `@fawazahmed0/currency-api@latest` and exposes frontend rate editing.
- Rates currently live in `GlobalContext` as `Record<string, number>`. They are lost on reload and
  use `number` / `parseFloat`, contrary to the project Decimal.js rule.
- `GlobalContext.addCurrency` cannot add a non-base currency. Currency and rate data are server state
  and should move to TanStack Query.
- `SettingsView` declares `CURRENCY`, but the settings router and main settings page do not fully mount
  the currency-management view.
- The add-account UI already has a currency selector, but it is disabled.
- Backend `resolveUserBaseCurrency` forces every account to use the user's base currency, and
  transaction validation applies the same restriction.
- Dashboard aggregation and the frontend trend chart skip mismatched currencies, which can return a
  plausible-looking but incomplete total.
- A transaction currently stores one amount and one currency. It cannot correctly represent a source
  amount, destination amount, and execution rate for currency exchange.

## 3. Weekly delivery scope

### 3.1 Rate and user-currency data model

Add versioned migration `2026081701_multi_currency_rates.sql` with:

- `user_currencies`
  - `user_id`
  - `currency_code`
  - `created_at`
  - primary key `(user_id, currency_code)`
- `exchange_rates`
  - `base_currency`
  - `quote_currency`
  - `rate_decimal NUMERIC(38,18)`
  - `rate_date`
  - `provider`
  - `fetched_at`
  - unique key `(base_currency, quote_currency, rate_date, provider)`
- `user_exchange_rate_overrides`
  - `user_id`
  - `base_currency`
  - `quote_currency`
  - `rate_decimal NUMERIC(38,18)`
  - `updated_at`
  - primary key `(user_id, base_currency, quote_currency)`

Backfill `user_currencies` from each user's `main_currency` and active account currencies. The
migration must not rewrite balances or historical transactions.

Rate semantics are fixed as:

```text
1 base_currency = rate_decimal quote_currency
```

For example, if `1 CNY = 0.1392 USD`, valuing USD in CNY divides the USD amount by that rate. The
backend uses `shopspring/decimal`, the frontend uses `decimal.js`, and protobuf transfers rates as
decimal strings. Converting to Money's nine nanos uses banker's rounding.

### 3.2 Provider and synchronization policy

Define a replaceable logic-layer interface:

```go
type ExchangeRateProvider interface {
	FetchRates(
		ctx context.Context,
		baseCurrency string,
		quoteCurrencies []string,
	) ([]ExchangeRate, error)
}
```

Implement only `FawazAhmedProvider` this week:

1. Request the minified jsDelivr JSON.
2. Fall back to Cloudflare Pages after a network error, timeout, non-2xx response, invalid JSON, or
   missing requested currency.
3. If both sources fail, preserve the last-known-good rates and never write empty or zero values.
4. Synchronize once per day and do not duplicate the same `rate_date`.
5. Mark the effective rate set `stale=true` after 48 hours without a successful update.
6. After an automatic or manual effective-rate change, invalidate affected Redis/PostgreSQL
   Dashboard snapshots and enqueue a RabbitMQ rebuild.

Persist `provider`, `rate_date`, and `fetched_at` for future `TwelveDataProvider` compatibility. Do
not introduce Twelve Data SDKs, credentials, or quota logic this week.

### 3.3 API, accounts, and transactions

Add user-scoped configuration APIs to:

- read tracked currencies, effective rates, provider, valuation date, and stale state;
- add or remove a tracked currency, while preventing removal of the base currency or a currency used
  by an active account;
- set or delete a manual rate override;
- request an automatic refresh for the current base currency.

Account and transaction rules:

- Beta/Free users may create standalone accounts in any supported currency; account creation tracks
  the selected currency automatically.
- Native balances and historical transaction currencies never change when the base currency changes.
- Income, expense, opening balance, and ordinary transfer transactions require matching account
  currencies.
- The transaction UI filters destination and instant income/expense accounts by source currency.
- Cross-currency ordinary transfers are rejected by frontend and backend without dirty balances or
  orphan accounts.
- Account groups, child accounts, and deep hierarchy remain deferred.

### 3.4 Dashboard and frontend

- Dashboard Summary and Monthly Stats use one effective rate snapshot and return base-currency Money.
- Responses add `base_currency`, `rate_date`, `stale`, `valuation_complete`, and
  `missing_currencies`.
- Missing rates are never silently skipped. The UI reports an incomplete valuation and does not show
  a total that could be mistaken for complete.
- The first 30-day trend implementation uses one latest effective snapshot and displays its valuation
  date. Per-day historical-rate valuation remains a later feature.
- Currency and rate server state moves from `GlobalContext` to TanStack Query.
- Restore the currency-management navigation, enable the account currency selector, and add every
  visible string to English, Japanese, Simplified Chinese, and Traditional Chinese locales.
- Perform monetary and rate calculations with Decimal. Convert to `number` only at the final Recharts
  rendering boundary.

### 3.5 VPS Telegram alerts

Use a host script and systemd timer running once per minute to detect:

- CPU or memory above 85% for five consecutive minutes;
- disk usage above 85%;
- three consecutive API readiness failures;
- unhealthy, restarting, or exited GAAP containers;
- sustained backlog in `gaap.dashboard` or `gaap.tasks`.

Apply a 30-minute suppression window and send one recovery message. Store the Telegram bot token and
chat ID only in `/opt/gaap/secrets/telegram.env` with mode `0600`; never expose them in the repository,
process arguments, or logs. Send notifications through the Telegram Bot API `sendMessage` endpoint.

## 4. Schedule: August 17–21

| Date | Primary work | Daily completion criterion |
|---|---|---|
| Mon, Aug 17 | Rate/user-currency migration, Provider contract, protocol, Telegram alert foundation | Existing data is backfilled without rewriting finances; Decimal boundaries pass; test alert succeeds |
| Tue, Aug 18 | FawazAhmedProvider, dual-host fallback, daily sync, manual overrides | Primary, fallback, last-known-good, stale, and override paths have automated tests |
| Wed, Aug 19 | Standalone multi-currency accounts, same-currency transactions, settings UI | CNY/USD/JPY accounts work; native transactions reconcile; cross-currency submission leaves no dirty state |
| Thu, Aug 20 | Dashboard Summary, Monthly Stats, and 30-day valuation | All convertible currencies are included; missing rates are explicit rather than silently omitted |
| Fri, Aug 21 | Full verification, generation checks, UAT, observation, conditional release | Reconciliation has no differences; production is enabled only after all gates pass |

Add `GAAP_MULTI_CURRENCY_ENABLED`, disabled by default. Enable it in UAT first and in production only
after the weekly gates pass. If work slips, protect native-currency correctness, missing-rate safety,
and boundary tests first. Production enablement, trend valuation, and the manual refresh button may
move; financial safety tests may not be removed to meet the date.

## 5. Test and acceptance gates

Financial changes require boundary coverage for:

- CNY-base users with simultaneous CNY, USD, and JPY standalone accounts;
- an exact base-currency rate of 1;
- zero, negative, malformed, and excessive-precision manual rates;
- positive, negative, maximum, one-nano, and midpoint-rounding conversions;
- manual override precedence and restoration of automatic rates after removal;
- jsDelivr failure followed by successful Cloudflare fallback;
- both sources failing while last-known-good rates remain available and stale;
- missing rates returning `valuation_complete=false` instead of silent omission;
- base-currency changes leaving native balances and history untouched;
- rejected cross-currency transactions leaving both balances and instant-created accounts unchanged;
- Beta/Free access to standalone multi-currency accounts while groups remain forbidden;
- rate changes invalidating and rebuilding Redis/PostgreSQL Dashboard snapshots;
- account, monthly, and trend views using one consistent effective snapshot;
- read-only reconciliation operating on native-currency ledgers, not display valuation;
- Telegram fixture/dry-run coverage for thresholds, suppression, recovery, and secret redaction.

Verification follows repository rules:

- run `go test ./...`; after logic changes run `gf gen service` and check generated drift;
- regenerate Go controllers/APIs and frontend TypeScript protobuf after protocol changes;
- run Vitest, ESLint, and TypeScript checks; do not run `npm build` in development;
- execute UAT with real PostgreSQL, Redis, RabbitMQ, protobuf, and ALE, ending with read-only
  reconciliation;
- maintain all UI strings in `en`, `ja`, `zh-CN`, and `zh-TW`.

## 6. Rolling medium- and long-term priority

Deferred test-case P0 means critical after a feature is opened; it does not automatically determine
product-development order. The roadmap order is:

1. Multi-currency accounts, daily reference rates, and base-currency valuation.
2. VPS resource and health alerts through Telegram.
3. Cross-currency exchange transactions, dual amounts, execution rates, and FX gains/losses.
4. Data export, secure download, and minimum task status.
5. 2FA, password changes, and account recovery.
6. Editable nickname and avatar.
7. Selected-month statistics and custom-range trends.
8. Account groups, child accounts, and mixed-currency group valuation.
9. Data import, task cancellation, and failed-task retry.
10. Migration-based deletion of transaction-bearing accounts.
11. Theme catalog and preference persistence.
12. Deep hierarchy, oversized imports, and other P2 boundaries.
13. Production backup scheduling and independent restore verification.

Twelve Data follows a stable cross-currency model. It is added through `TwelveDataProvider` as a
paid-user minute-level capability and must not change Free/Beta daily rates or manual overrides.


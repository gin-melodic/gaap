# Multi-currency UAT — Browser Mock Run Records

This file records the local-UAT browser mock execution for the Beta multi-currency extension (board #25/#26/#27/#29
and the UAT half of #28). The protocol-level regression suites remain in the module documents; these gates are the
multi-currency UI round driven by Playwright against the real ALE + protobuf HTTPS chain on `https://gaap.local`.

## Test account

- Demo user resolved by the UAT stack from `.env.uat` (`ONLINE_DEMO_USER_*`): email `gaap_test_feedback@ginmel.ai`,
  nickname `demo_user`, base currency `CNY`, plan FREE.
- Login path: the "Try the demo user" button, which authenticates through `/v1/auth/demo-login` using the
  server-side env credentials (no browser-side password or Turnstile).

## Environment

- Stack: `docker compose --env-file .env.uat -f docker-compose.uat.yml up -d --build` (2026-09-07), `gaap-api`/`gaap-web`
  images rebuilt from the multi-currency working tree.
- Migration `20260907_create_exchange_rates.sql` auto-applied on boot (`exchange_rates` present).
- Reference-rate sync populated on startup: `USD→CNY 6.711861430`, `USD→EUR 0.860811770`, `USD→HKD 7.840502390`,
  `USD→JPY 156.249690770` (source `reference`, fetched 2026-09-07T07:23:34Z).

## Run 2026-09-07 — `local-uat-multicurrency-browser.mjs`

Driver: `gaap-web/scripts/local-uat-multicurrency-browser.mjs` (Playwright chromium, headless, `ignoreHTTPSErrors`).
All API responses during the run returned 200; console error count 0.

| Gate | Result | Evidence |
|---|---|---|
| MC-LOGIN-DEMO | PASS | redirected to `/dashboard`, email `gaap_test_feedback@ginmel.ai` |
| MC-RATES-DISPLAY | PASS | CNY row shows `1 USD ≈ 7.2 CNY` |
| MC-RATE-OVERRIDE | PASS | manual `USD→CNY = 7.2` persisted (source `manual`) |
| MC-ACCOUNT-CURRENCY-ENABLED | PASS | Add Account currency combobox enabled |
| MC-ACCOUNT-CREATE-USD | PASS | toast `Account created successfully`, account `mc-usd-asset` (USD, 100) |
| MC-DASHBOARD-VALUATION | PASS | Net Worth `¥720.00` (100 USD × 7.2 CNY) |

## Ledger reconciliation (read-only, post-run)

```
docker compose --env-file .env.uat -f docker-compose.uat.yml run --rm --no-deps gaap-api ./reconcile
{ "passed": true, "accountsChecked": 80, "transactionsChecked": 36, "differences": [], "issues": [] }
```

Creating the USD asset account auto-generated its balancing `Opening Balance - USD` equity voucher (currency `USD`,
-100), so the ledger remains zero-sum across currencies; the manual `USD→CNY` override was preserved and not
overwritten by the daily reference sync.

## Notes

- The `CurrencySettings` view was not reachable from the settings navigation in the initial build; fixed by wiring the
  `CURRENCY` view into `Settings.tsx` and making the "Currency Management" row in `MainSettings.tsx` navigate to it.
  The web image was rebuilt after this fix.
- Remaining for #28: the release-owner conditional release call (free-plan multi-currency is currently available to all
  logged-in users; no new plan gate was added this round). #30 (Telegram VPS alerts) stays out of scope.

## Run 2026-09-08 — Interactive browser-bridge UAT (round 2: transactions + Currency Management)

Driver: DSH browser bridge against `https://gaap.local` (same UAT stack and demo user as 2026-09-07, no rebuild).
This round covers the transaction-creation paths and the full Currency Management page — neither had browser gates on
2026-09-07. Entering "Currency Management" required ONE manual mouse click (div+onClick sub-nav row not addressable by
DOM automation — DEF-031); everything after that was automated.

| Gate | Result | Evidence |
|---|---|---|
| MC-TXN-SAMECCY-EXPENSE | PASS | USD → newly created USD expense account "UAT SameCcy Expense", US$5.00 committed (2026-09-08 15:57:39 +08); `mc-usd-asset` balance US$95.00; success toast |
| MC-TXN-CROSSCCY-TRANSFER | REJECTED BY DESIGN / UX GAP | EUR→USD and USD→EUR transfers between asset accounts rejected server-side with HTTP 400 `account currency mismatch` (`validation.go:86`, both legs must share the transaction currency); no ledger row committed in any of the 5 attempts. UX gap = DEF-030, error display = DEF-028 |
| MC-TXN-SAMEACCT-TRANSFER | SERVER GUARD PASS / DISPLAY FAIL | Same FROM/TO rejected with HTTP 400 `source and destination accounts must differ`; UI shows only the generic ALE toast → DEF-028 |
| MC-DASHBOARD-MULTICCY-VALUATION | PASS | Net Worth `(CNY) ¥1,102.21` = US$95 × 7.2 (manual) + €50 × (USD→EUR reference inverted) × 7.2 — matches an independent cross-calculation exactly; Monthly Overview Expense `¥36.00` = the US$5 expense converted at the manual rate |
| MC-RATES-DISPLAY-ROUND2 | PASS | CNY row shows `1 USD ≈ 7.2 CNY` (manual override still intact after reference sync); HKD/EUR/JPY show 2026-09-07 reference values, DB `source='reference'` unchanged |
| MC-RATE-MANUAL-EDIT | PASS | Edited CNY rate 7.2 → 7.15 via the row pencil: persisted with `source='manual'` in `exchange_rates` (DB-verified); restored to 7.2 after the test, source stays manual |
| MC-CURRENCY-ADD | PASS | Added "GBP" → new row appears ("Missing rate"), GBP becomes selectable as base currency; input clears and Add re-disables when empty |
| MC-CURRENCY-DELETE | PASS | Deleted GBP with one click → gone from list and DB (0 rows); CNY/USD/current-base delete guards confirmed by code inspection (`CurrencySettings.tsx:240`) |
| MC-BASE-SWITCH | FAIL | Double-click confirm UI works (button re-labels to "Confirm" for 3 s), but confirming shows toast `Failed to update base currency` ×2; `users.main_currency` remains CNY. No trace of the request in available logs — see DEF-029 and the observability note below |

**New defects raised:** DEF-028 (ALE error channel masks all validation errors, P1), DEF-029 (base-currency switch
fails, P1), DEF-030 (cross-currency transfer UX gap, P2), DEF-031 (settings sub-nav a11y/automation, P2), DEF-032
(RabbitMQ 127.0.0.1:5772 leak + log flood/gap in the UAT image, P2). See `defects.md`.

### Error-channel finding (DEF-028) — evidence chain

Server side is correct: gaap-api access logs show proper HTTP 400s with readable reasons (`account currency mismatch`,
`source and destination accounts must differ`) for every failing create attempt; the ALE response middleware writes an
encrypted protobuf `ErrorResponse` signed/encrypted with the same per-session key that just decrypted the request.
Client side (`secure-client.ts`): any `decryptPayload` throw on a session-keyed call triggers `attemptTokenRefresh()` —
which is a no-op for genuine desync because refresh keeps the same ALE key (server only extends its TTL) — then re-tries
once and finally throws `ApiError('Unable to verify secure API response', 502)`; callers surface that generic message.
Result: NO server validation error on an ALE route is ever readable by the user in this build.

### Observability gap found while triaging (DEF-032) — corrected after deeper log forensics

Initial reading of `logs/api.log` suggested the UAT API container carried a leaked dev RabbitMQ config
(`127.0.0.1:5772`). Deeper inspection shows that is **not** what happened to the container:

- The running container has correct compose env (`RABBITMQ_HOST=rabbitmq`, `PORT=5672`, user `gaap_uat`); no
  `.env` file is baked into the image (`/app/.env` absent).
- The RabbitMQ broker log shows the api container's IP authenticating and connecting normally at boot on
  09-07 15:23 +08 (container `StartedAt`) — the UAT AMQP link was healthy.

The real findings, both confirmed with `lsof`/`ps`, are two-fold:

1. **`logs/api.log` is a host-side dev log file.** Multiple local gaap-api dev runs (`./main | tee logs/api.log`,
   three live `tee` writers with cwd `gaap-api/`) keep writing RabbitMQ reconnect spam against `127.0.0.1:5772`
   (the dev `.env` value; nothing listens on 5772 on the host). The UAT container does not write to this file at
   all — triage initially mistook its contents for container output, and one of those dev runs also binds host
   `:8000`, which is *not* what Caddy proxies (Caddyfile.uat targets `gaap-api:8000`, the compose service).
2. **The production image logs only to stdout, with no persistent file adapter.** After ~16:08 +08 (~24 h 45 m
   uptime) `docker compose logs gaap-api` went completely silent — zero new lines through 15+ minutes of live
   traffic (GBP add/delete, dashboard loads, navigation) while healthchecks stayed green. That silence is what hid
   DEF-029's request trail; whether the failed base-currency switch ever produced a server-side log line cannot be
   determined until either fix lands.

### Data mutated this round (demo user; retained as UAT evidence)

- Account `uat-eur-card` (EUR, opening balance €50.00) + its auto `Opening Balance - EUR` equity voucher
- New USD expense account "UAT SameCcy Expense" (balance −US$5.00) and the US$5.00 same-currency expense transaction
  (2026-09-08 15:57:39 +08, `mc-usd-asset` → "UAT SameCcy Expense")
- Currency GBP added then deleted (net zero in `exchange_rates`)
- Manual USD→CNY rate round-trip 7.2 → 7.15 → 7.2; final state: source `manual`, value 7.2

Expected balances at end of round: `mc-usd-asset` US$95.00, `uat-eur-card` €50.00; base currency CNY unchanged (the
failed switch did not mutate it).

## Ledger reconciliation (read-only, post-run 2026-09-08)

```
docker compose --env-file .env.uat -f docker-compose.uat.yml run --rm --no-deps gaap-api ./reconcile
{ "passed": true, "accountsChecked": 83, "transactionsChecked": 38, "differences": [], "issues": [] }
```

The +2 transactions vs the 09-07 round are exactly this run's two committed entries (EUR opening-balance voucher and the
US$5 expense). The 4 rejected cross-currency attempts and the rejected same-account attempt left no rows behind — no
duplicates, no orphans.

## Fix run — DEF-028 (ALE error channel), 2026-09-08 ~17:10 +08

**Root cause (wire-proven before fixing).** A raw capture of a pre-fix `HTTP 400` error response from
`/v1/transaction/create-transaction` began with the bytes `42 61 64 20 52 65 71 75 65 73 74` — the literal status text
"Bad Request" — *ahead of* the ALE envelope (`Content-Type: application/octet-stream`, `X-ALE-Encrypted: 1`, no
Content-Encoding). GoFrame's `Response.WriteStatus(status)` writes the default status text into the buffer when called
without a content argument; our middleware then appended the encrypted body, so the client sliced bytes `[0:12]` as IV
from "Bad Request"+ciphertext and AES-GCM auth failed on **every** encrypted 4xx (status-text length shifts the offset),
while all 2xx bodies — written via `Write()` only — decrypted fine.

**Fix.** `internal/middleware/proto_error.go`: `writeProtoError` now clears the buffer, sets status with
`Response.WriteHeader(status)` and then writes exactly one body; error-body construction factored into testable
`protoErrorBody()`. No ALE protocol/client changes (per constraint). Commits in `gaap-api`: multicurrency baseline
`48fe2874`, DEF-028 fix + tests **`9ef54b53`**. Rebuilt image on the UAT stack (`gaap-api:uat-local`), healthy.

**UAT data restoration (recorded before mutation).** Post-run forensics showed the multi-currency demo data had been
reset away after this round (all 96 accounts CNY under `uat-20260813-a@gaap.local`; demo user owned zero; reconcile at
78 accts / 35 txns). Restored through the real ALE endpoints with a new env-gated harness
(`internal/middleware/ale_demo_seed_test.go`, run as `GAAP_UAT_SEED=1 go test -run TestALEUATDemoSeed`):

- created `mc-usd-asset` (USD, opening US$100), "UAT SameCcy Expense" (USD expense account), `uat-eur-card` (EUR,
  opening €50 + auto equity voucher) — same names/balances as the original round
- manual USD→CNY rate = 7.2 (`source='manual'`)
- committed US$5.00 same-currency expense (`mc-usd-asset` → "UAT SameCcy Expense")

Post-restoration reconcile: `passed:true, accountsChecked 83, transactionsChecked 38` — identical to the post-run
2026-09-08 state above; final balances US$95.00 / €50.00 as documented there. The harness also supports
`GAAP_UAT_DELETE_TXN_ID` (delete-only mode) used once below for cleanup.

**Verification (self-proof).**

1. Wire probe (`ale_probe_test.go`, `GAAP_UAT_PROBE=1`): both DEF-028 repros now return `HTTP 400` whose bodies decrypt
   with the *session* key to exactly `account currency mismatch` and
   `source and destination accounts must differ` (raw and browser-like header variants).
2. Browser run (`gaap-web/scripts/local-uat-def028-browser.mjs`, demo login via "Try the demo user", real transfer form):

```
BROWSER-DEF028-CROSS-CCY  PASS  toast=["account currency mismatch"]                     400 /api/v1/transaction/create-transaction
BROWSER-DEF028-SAME-ACCT  PASS  toast=["source and destination accounts must differ"]   400 /api/v1/transaction/create-transaction
BROWSER-DEF028-CONTROL-USABLE PASS  same-currency US$1 expense committed (200 create-transaction, success toast, list row)
```

No generic `Unable to verify secure API response` fallback in any case; both failed submits left the dialog open with no
ledger rows. The control txn (`def028-control-usable`) was deleted afterwards via
`GAAP_UAT_DELETE_TXN_ID=… GAAP_UAT_SEED_ONLY_DELETE=1`, restoring `mc-usd-asset` to US$95 and reconcile to 83/38.

Unit tests added: `TestALEErrorResponseRoundTrip` (400×2/401/403/404/500 round-trip through the ALE envelope with
regression assertion that dropping byte[0] breaks GCM auth) and `TestALEErrorResponsePlainPath`; full `go test ./...` green.

Status in `defects.md`: **IMPLEMENTED** (pending next UAT re-confirmation).

## Fix run — DEF-029 (base-currency switch), 2026-09-08 ~17:35 +08

**Root cause (wire-proven).** With the DEF-028 fix in place, a new env-gated live probe
(`internal/middleware/ale_profile_test.go`, run as `GAAP_UAT_PROFILE=1 go test -run TestALEUATUpdateProfile`) posted
exactly what the Currency Settings UI sends (`nickname=demo_user, plan=1, mainCurrency=USD`) through the real ALE
session channel and read back: pre-fix → **`HTTP 404 "feature unavailable in beta"`**. `BetaScopeMiddleware` deferred
*every* `/v1/user/update-*` path (a blanket prefix rule) with an ALE-encrypted 404 on production runtimes — including
update-profile, the only endpoint that persists `users.main_currency`. The demo user's email is *not* in
BETA_ALLOWED_EMAILS, but the gate was path-based and applied to all users; no request ever reached `GfUpdateProfile`,
which is also why pre-DEF-028 there was nothing but a generic toast client-side.

**Fix.** `internal/middleware/beta_scope.go`: update-profile removed from the deferred set (core multi-currency
functionality); only the not-yet-shipped `/v1/user/update-theme` stays 404. Commit **`6a4346e`**; unit test
`TestDeferredBetaPaths` updated. No demo data was mutated by this fix or its verification beyond a profile round-trip
that ends at the original value (CNY).

**Verification.**

1. Wire: post-rebuild, `GAAP_UAT_NEW_CURRENCY=USD` → `HTTP 200`, decrypted `main_currency="USD"`, `base="success"`;
   then `GAAP_UAT_NEW_CURRENCY=CNY` → back to CNY (round-trip proven at API level).
2. Browser run (`gaap-web/scripts/local-uat-def029-browser.mjs`, demo login, real double-click confirm flow):

```
BROWSER-DEF029-SWITCH-TO-USD   PASS  toast=["Base currency updated"]  200 /api/v1/user/update-profile  target selected+disabled
BROWSER-DEF029-DASH-USD        PASS  dashboard shows "Net Worth (USD) US$153.05", "Monthly Overview (USD)", Expense US$5.00
BROWSER-DEF029-SWITCH-BACK-CNY PASS  toast=["Base currency updated"]  200 /api/v1/user/update-profile
```

`users.main_currency` verified `CNY` in the DB after the run (demo state unchanged); read-only reconcile re-checked
green at exactly 83 accounts / 38 txns.

**Payload unit test.** `gaap-web/src/lib/proto/user/v1/user.updateProfile.test.ts` (5 tests, gaap-web commit
`a286655`) pins the wire payload: mainCurrency present on the wire when set (field-4 tag check), omitted when absent
(a plain profile update must not clear the base currency), plan survives encode/decode without enum mangling, and the
`UpdateUserProfileReq` envelope wraps the input intact. Full gaap-web suite green (106 passed / 10 pre-existing skips).

Status in `defects.md`: **IMPLEMENTED** (pending next UAT re-confirmation). Note for DEF-031: entering Currency Management
still requires a mouse click on the settings sub-nav row — its keyboard/DOM visibility fix is tracked separately and is not
part of this change.

---

## Fix run — DEF-030 (cross-currency transaction dropdowns), 2026-09-08 ~17:36 +08

**Behavior before the fix.** `Transactions.tsx` rendered every asset/liability/expense/income account in both the From and
To dropdowns regardless of currency. The server is strict — `validateTransactionAccounts` (gaap-api
`internal/logic/transaction/validation.go`) requires **both legs to share one currency** for every transaction type, so a
USD user who picked FROM=mc-usd-asset could still select TO=uat-eur-card and only be rejected at submit time.

**Fix.** gaap-web commit `ef77043` (on baseline `a286655`, i.e. after the DEF-029 payload tests): a same-currency filter
(`sameCurrencyAsSelection`) now applies to every real-account group in both dropdowns as soon as any concrete account is
picked on either side; NEW_INCOME / NEW_EXPENSE stay unfiltered because their auto-created accounts inherit the opposite
leg's currency by design. `handleFromChange`/`handleToChange` additionally clear a stale incompatible other-side selection,
so an edit-prefill or data-change edge case can no longer leave a pair the server would reject. Server guard unchanged.

**Verification.** Rebuilt `gaap-web:uat-local` offline (Dockerfile line-1 syntax hint deleted for the build, restored after)
and restarted the service; new Playwright gate driver `scripts/local-uat-def030-browser.mjs`:

```text
BROWSER-DEF030-BASELINE                 PASS  TO before any selection offers both: ["+ New Expense Account...", "UAT SameCcy Expense", "mc-usd-asset", "uat-eur-card"]
BROWSER-DEF030-CROSSCCY-HIDDEN          PASS  FROM=mc-usd-asset -> TO list = [NEW_EXPENSE, UAT SameCcy Expense, mc-usd-asset]; uat-eur-card unavailable
BROWSER-DEF030-CROSSCCY-HIDDEN-SYMMETRIC PASS  TO=UAT SameCcy Expense (USD) picked first -> FROM list = [mc-usd-asset, NEW_INCOME]; uat-eur-card unavailable
BROWSER-DEF030-SAMECCY-STILL-USABLE     PASS  same-currency US$1 expense committed: successToast=true rowSeen=true (note def030-control)
```

The control txn was deleted through the real ALE endpoint (`TestALEUATDemoSeed` delete-only mode,
`GAAP_UAT_DELETE_TXN_ID=01a0805d-e362-7d15-894f-7e9b724b6047`, base message "success"), restoring mc-usd-asset to exactly
US$95; read-only reconcile re-checked green at exactly 83 accounts / 38 txns. Full gaap-web suite stays green (106 passed /
10 pre-existing skips).

Status in `defects.md`: **IMPLEMENTED** (pending next UAT re-confirmation).

---

## Fix run — DEF-031 (settings/sidebar keyboard accessibility), 2026-09-08 ~17:45 +08

**Fix.** gaap-web commit `6349bcd` (on baseline `ef77043`, the same UAT web image also carries DEF-030): all four
MainSettings clickable divs — Profile card, Appearance & Theme row, **Currency Management** row, Language Preference row —
and the Sidebar avatar/profile shortcut now expose `role="button"`, `tabIndex=0`, Enter/Space activation and an
`aria-label` matching the visible label; a focus-visible ring renders for keyboard focus only, so mouse styling is
unchanged. The Dashboard trend "Select Accounts" trigger was inspected first: current source already renders a native
`<Button>` inside `DropdownMenuTrigger asChild`, so no code change — verified live instead.

**Verification.** Rebuilt `gaap-web:uat-local`, restarted the service, ran new Playwright gate driver
`scripts/local-uat-def031-browser.mjs`:

```text
BROWSER-DEF031-CURRENCY-KEYBOARD          PASS  Tab x12 focused div[role=button][aria-label="Currency Management"]; Enter switched to Currency Management (Base Currency section visible)
BROWSER-DEF031-SIDEBAR-AVATAR-KEYBOARD    PASS  shortcut has role/tabindex + aria-label "demo_user Settings"; Enter navigated /accounts -> Profile settings view
BROWSER-DEF031-SELECT-ACCOUNTS-BUTTON     PASS  "Select Accounts" trigger is a native <button>; Enter opened the account menu (no code change needed)
```

No data written by this run; demo state untouched. Full gaap-web suite stays green (106 passed / 10 pre-existing skips).

Status in `defects.md`: **IMPLEMENTED** (pending next UAT re-confirmation). This removes the manual-click step from the
Currency Management entry path that earlier runs noted as a DEF-031 pointer.

---

## Fix run — DEF-032 (UAT env/observability: dev log spam + prod file logging), 2026-09-08 ~17:45–18:05 +08

**Part a — host dev side.** The RabbitMQ reconnect flood came from three orphaned host pipelines writing
`logs/api.log`: two terminal `air | tee` runs left over from 2026-09-04 and one `screen -dmS gaap-api ./tmp/main |
tee` that was still LISTENing on unproxied :8000. All three were killed (verified: no surviving processes, port free)
and the polluted file archived as `logs/api.log.stale-20260908`. The root cause of part a is an environment gap, not a
config error: dev `.env` dials broker `127.0.0.1:5772`, which is exactly what the canonical dev middleware stack
publishes — it simply wasn't running. `start-dev.sh` changes (parent repo): log output renamed everywhere to distinct
`logs/gaap-api-dev.log`; screen build command made POSIX (`air -build.cmd 'sh hack/build_dev.sh' …` — the bare
`.air.toml` cmd is Windows-only: `cmd /c hack\build_dev.bat`); pre-flight broker check that warns before booting when
`127.0.0.1:$RABBITMQ_PORT` is unreachable (negative-tested with the broker stopped). Fresh run
`./start-dev.sh start api` against the now-running dev middleware:

```text
logs/gaap-api-dev.log  2026-09-08T17:58:06.269+08:00 [INFO] RabbitMQ connected successfully
reconnect/refused lines in log: 0        (was one "connection attempt N failed … dial tcp 127.0.0.1:5772" every ~4 s)
curl http://127.0.0.1:8000/v1/health/ready -> {"status":"ready"}   (dev api left running as final dev state)
```

**Part b — UAT container side.** Root cause of the "silent after 24 h" symptom: ghttp access logging was never enabled
(`server.accessLogEnabled` defaults false), so request-level lines were not part of stdout at all; with `logger.level:
warning`, a quiet day legitimately produced zero app-log lines — there is no level filter that can drop the now-enabled
access output, because gf writes it via level-agnostic `glog.Print`. Changes (gaap-api `b944496` + parent compose):
`config.prod.yaml` sets `server.logPath: /app/logs`, `accessLogEnabled: true`, `accessLogPattern: access-{Ymd}.log` and
points the global logger at `/app/logs/{Y}{m}{d}-api.log`; Dockerfile pre-creates gaap-owned `/app/logs` (read_only root
+ named-volume copy-up needs a writable directory owned by uid 1001); compose mounts new `api_logs` volume on
`/app/logs`. Rebuilt `gaap-api:uat-local`, recycled, and verified live:

```text
docker logs gaap-api (one line per request, incl. every healthcheck):
  2026-09-08T17:52:25.866+08:00 {…} 200 "GET https gaap.local /v1/health/ready HTTP/1.1" 0.004, 192.168.65.1, "", "curl/8.7.1"
/app/logs in container: access-20260908.log (per-day access file) + 20260908-api.log (app WARN+, level=warning confirmed applied — boot INFO lines correctly absent)
persistence proof: pre-restart first line retained after `docker compose restart gaap-api` and post-restart requests appended (36 -> 40 lines); host volume gaap-uat_api_logs carries the data
```

Read-only reconcile re-run on the final image: green at exactly **83 accounts / 38 txns**, `differences: []`,
`issues: []`. No data was written by this fix run (health probes + one plain-JSON demo-login rejected 415 before any
handler, as expected for a non-ALE client). ALE protocol shape untouched; gaap-web unchanged. Remaining UAT-side
confirmation is the next round's long-uptime observation (24 h+ → docker logs still carries access lines, day file
rotates by name pattern); no code change expected there.

Status in `defects.md`: **IMPLEMENTED** for both parts (pending next UAT re-confirmation).

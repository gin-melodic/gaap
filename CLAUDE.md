# GAAP Project Rules & Guidelines

## 🎯 Global Core Rules
- **No Floats for Money**: Backend MUST use `shopspring/decimal`. Frontend MUST use `decimal.js`.
- **Vibe Coding**: NEVER use placeholders like `// ...`. Output full file content.
- **Verification**: All financial logic changes MUST include boundary tests.

## 🛠 Backend (GoFrame 2.x)
- **Logic Layer**: Implementation in `internal/logic/`. Use `gf gen service` after changes.
- **ORM**: Strictly use DAO Columns. No hardcoded strings for DB fields.
- **Transactions**: Mandatory for multi-query operations.

## 🎨 Frontend (Next.js 16)
- **i18n**: All UI strings must be in `src/locales/` (en, ja, zh-CN, zh-TW).
- **State**: Use TanStack Query for server state.
- **Math**: Use `Decimal.js` for all balance displays.

## 🏗 Infrastructure
- **Dev Workflow**: Strictly use `npm run dev` and `air` inside Docker. No `npm build` in dev.
- **Migrations**: Auto-run from `manifest/sql/`. Never skip for schema changes.

## 🧪 UAT Testing — Default User
- **Default UAT user**: When no UAT user is specified, use the **Test User**.
- **Credentials**: Read via `source .env.uat` → `TEST_USER_NAME` / `TEST_USER_EMAIL` / `TEST_USER_PASSWORD`.
- UAT stack: `docker-compose.uat.yml`; site `gaap.local` (Caddy internal CA); automated browser traffic goes through a temp proxy on `127.0.0.1:8080` (upstream `127.0.0.1:443`, SNI `gaap.local`, cert check off) to bypass the cert warning.
- Turnstile on UAT uses the official test key (`1x00000000000000000000AA`): widget shows "Success!" and emits the token automatically; `siteverify` accepts any non-empty token for the test key.
- API protocol: ALE-encrypted protobuf (AES-256-GCM; bootstrap key = `NEXT_PUBLIC_ALE_BOOTSTRAP_KEY`; `X-Signature` = hex HMAC-SHA256 over IV + ciphertext-incl-tag + timestamp + nonce).
- Status (2026-09-10): Test User registered on UAT via the browser registration page (toast "注册成功" → auto-login to /dashboard; confirmed in `users` table).
- Status (2026-09-10): Test User full ledger ingested from `consume_records.xlsx`: 5 asset accounts (CMB ¥86,243.57 / Alipay ¥1,520 / BOC HK HK$98,600 / CMB USD $3,500 / VND ₫12.5M) + 2 liabilities (notes carry 月供 terms) + 23 expense-category accounts (per-currency CNY/HKD/VND — the API requires both transaction legs to share the currency) + 1 income account (工资薪金) + all 102 transactions (2026-08-01…09-09). Batch tool: `gaap-api/hack/uat_ingest/` (ALE-protobuf client; login may need retries because Cloudflare siteverify is flaky; idempotent dedup by date|note|amount|from|to; `INGEST_CLEANUP=1` deletes duplicate copies via the API so balances reverse correctly).
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
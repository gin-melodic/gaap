# GAAP - AI Coding Instructions

**Project**: GAAP (Generally Accepted Accounting Platform) - A modern, self-hosted personal finance system  
**Stack**: Go (GoFrame) backend + Next.js 16 frontend + PostgreSQL + Redis + RabbitMQ  
**Philosophy**: "AI-Native Development" with strict verification for financial correctness

---

## 🏗️ Architecture Overview

### Backend (Go/GoFrame)
- **Router**: `internal/cmd/cmd.go` defines all routes and middleware
- **Controllers** (`internal/controller/{domain}/`): Handle HTTP requests, convert Protobuf ↔ models
- **Logic** (`internal/logic/{domain}/`): Business logic and orchestration (imports auto-registered)
- **DAO** (`internal/dao/`): Database access layer for CRUD operations
- **Models** (`internal/model/`): Entity definitions and request/response types
- **Bootstrap** (`internal/boot/`): Database migrations, Redis, RabbitMQ, ALE encryption initialization

### Frontend (Next.js 16)
- **App Router**: `src/app/{route}` structure with layout inheritance
- **Components**: `src/components/ui/` (Radix UI base) + `src/components/features/` (feature-specific)
- **Hooks**: `src/lib/hooks/useAuth.ts`, `useAccounts.ts`, `useTransactions.ts` (TanStack Query)
- **Services**: `src/lib/services/` handle API calls with secure token management
- **Types**: Protobuf-generated types in `src/lib/proto/` + re-exported in `src/lib/types.ts`
- **i18n**: Full translation support (en, zh-CN, zh-TW, ja) in `src/locales/`

### Data Flow
1. **Frontend**: Component calls hook → Mutation via `secureAuthService` → TanStack Query handles caching
2. **Backend**: Controller receives request → Converts Protobuf to model → Calls logic → DAO queries DB → Returns Protobuf

---

## 🔑 Critical Patterns & Conventions

### Financial Data Handling (NON-NEGOTIABLE)
- **Decimal.js** (frontend) / **shopspring/decimal** (backend): NEVER use floats for money
- **Property-based tests required**: Any PR modifying ledger/balance logic must include boundary tests
  - Test: zero values, negative balances, precision loss, currency conversion edge cases
- **Reference**: See `dev-guild.md` section "Boundary Verification Strategy"

### Protobuf-First API Design
- **Definition**: `gaap-api/manifest/protobuf/` contains all `.proto` files
- **Generation**: Frontend: `npm run proto` generates `src/lib/proto/`
- **Controllers convert**: Protobuf request → internal model → DAO → Protobuf response
- **Example**: `internal/controller/auth/auth.go` shows `userEntityToProto()` pattern

### Authentication & Token Management
- **JWT**: Access token (short-lived) + Refresh token (long-lived)
- **Frontend secure service**: `src/lib/services/secureAuthService.ts` intercepts requests, auto-refreshes tokens
- **Backend middleware**: `internal/middleware/auth.go` validates JWT, checks token expiry
- **ALE Encryption**: `internal/ale/ale.go` - Application Layer Encryption for sensitive data (initialized in `boot.go`)

### Database & Redis
- **Migrations**: `gaap-api/manifest/sql/` auto-run on startup via Docker entrypoint
- **DAOs auto-generated**: Edit only custom methods in `internal/dao/*.go`
- **Redis caching**: Used for session management and balance sync (see `boot.SyncBalances()`)
- **Distributed lock**: Redis locks prevent race conditions in async operations

### Frontend State Management
- **TanStack Query**: Primary state layer for server sync + caching
- **Query keys pattern**: `{ keys: { profile: ['auth', 'profile'] } }` in `useAuth.ts`
- **Local state**: React hooks only for UI-local concerns (form inputs, modals)
- **Token storage**: `localStorage` via `secureAuthService` (cleared on logout)

---

## ⚙️ Developer Workflows

### Start Development Environment
```bash
cd gaap
cp .env.example .env
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f gaap-api
docker-compose -f docker-compose.dev.yml logs -f gaap-web
```

### Backend Development (Go)
```bash
# Hot reload: enabled by default via Air in Dockerfile.dev
# Tests: `go test ./...` (inside container or locally with Go 1.24+)
# Debugging: Set ENABLE_DELVE=true in .env, attach debugger on port 40000
```

### Frontend Development
```bash
# Inside gaap-web container, auto-restarts on save
npm run dev

# Generate Protobuf types after .proto changes
npm run proto

# Run tests
npm run test

# Build for production
npm run build
```

### Access Points
- **Frontend**: https://gaap.local (via Caddy reverse proxy)
- **API**: https://gaap.local/api/v1/* (routed by Caddy)
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)
- **Postgres**: localhost:5432 (configured in .env)
- **Redis**: localhost:6379 (configured in .env)

### Debugging Go in VSCode
1. Set `ENABLE_DELVE=true` in .env
2. Restart service: `docker-compose -f docker-compose.dev.yml restart gaap-api`
3. Create `.vscode/launch.json` with remote attach on port 40000
4. Press F5, set breakpoints, trigger API calls

---

## 📋 Key Files & Responsibilities

| File/Directory | Purpose |
|---|---|
| `gaap-api/main.go` | Entry point, calls `cmd.Main.Run()` |
| `internal/cmd/cmd.go` | Route registration & middleware setup |
| `internal/controller/{domain}` | HTTP handlers, Protobuf ↔ model conversion |
| `internal/logic/{domain}` | Business logic, orchestrates DAO calls |
| `internal/dao/{entity}.go` | Database queries (extend custom methods) |
| `internal/boot/boot.go` | Initialization: DB, Redis, RabbitMQ, ALE |
| `gaap-web/src/app/` | Next.js pages (App Router) |
| `gaap-web/src/lib/hooks/` | Custom React hooks with TanStack Query |
| `gaap-web/src/lib/services/` | HTTP clients, Auth token management |
| `docker-compose.dev.yml` | Local dev stack: Caddy, Go, Next.js, Postgres, Redis, RabbitMQ |
| `dev-guild.md` | Comprehensive local development guide |

---

## 🚀 Common Implementation Tasks

### Adding a New API Endpoint
1. Define Protobuf message in `gaap-api/manifest/protobuf/{domain}/v1/{domain}.proto`, then run `go run utility/genctrl/main.go` to generate API contract and controller boilerplate
2. Create/update controller method in `internal/controller/{domain}/{domain}.go`
3. Implement logic in `internal/logic/{domain}/{domain}.go`, then use `gf gen service` to generate service boilerplate
4. Use DAO in logic to query database. If table strcucture changes, use `gf gen dao` to update DAO and entity definitions in `internal/model/{do, entity}/*.go`. Create Input/Output structs for service calls if needed which locatated in `internal/model/{domain}/`.
5. Return Protobuf response from controller
6. Frontend: `npm run proto` to regenerate types, create hook in `src/lib/hooks/use{Domain}.ts`

### Adding a Frontend Feature
1. Create component in `src/components/features/{feature}/`
2. Create hook in `src/lib/hooks/use{Feature}.ts` (wraps service calls with TanStack Query)
3. Service calls go through `src/lib/services/secureAuthService.ts` (token auto-refresh)
4. Add translations to `src/locales/{lang}.json`
5. Test with `npm run test`

### Modifying Financial Logic
1. **Backend**: Implement in Go with `shopspring/decimal`
2. **Frontend**: Mirror logic in TypeScript with `Decimal.js`
3. **Testing**: Write boundary tests covering edge cases (zero, negative, precision loss)
4. **Verification**: Property-based tests must prove mathematical correctness

---

## 🔐 Critical Do's & Don'ts

### ✅ DO
- Use Protobuf for all API contracts (type-safe serialization)
- Use decimal types for all financial calculations
- Write tests for ledger/balance logic (non-negotiable)
- Use TanStack Query for server state on frontend
- Auto-refresh tokens via `secureAuthService` (no manual token management)
- Add i18n translations when adding user-facing strings

### ❌ DON'T
- Use floating-point numbers for money (even temporarily)
- Bypass auth middleware for "admin" endpoints
- Store tokens in global variables (use localStorage + React context)
- Hardcode environment values (use `.env`)
- Skip migrations for schema changes (always create SQL migration files)
- Modify auto-generated files directly (extend with new custom methods) which contains declaration of comments like `// This file is auto-generated by ...`

---

## 🏗️ Next.js & React Patterns

- **Server Components**: Default in App Router (use for data fetching, no hooks)
- **Client Components**: Use `'use client'` only when hooks/interactivity needed
- **Dark Mode**: `next-themes` with `useTheme()` hook (system default fallback)
- **UI Components**: Built on Radix UI (unstyled, accessible) + Tailwind styling
- **Icons**: Lucide React for all icon needs
- **Toasts**: Sonner library (`toast.success()`, `toast.error()`)

---

## 🔗 Integration Points

- **PostgreSQL**: ACID compliance for ledger integrity
- **Redis**: Session caching, distributed locks, real-time data sync
- **RabbitMQ**: Async task processing (optional in lite mode)
- **Caddy**: Reverse proxy with automatic HTTPS + certificate management
- **WebSocket** (`internal/ws/`): Real-time updates (if implemented)

---

## 📚 Project Philosophy

This project embodies **"Vibe Coding"** - leveraging AI for velocity while enforcing **"Boundary Verification"** for financial accuracy:

1. **AI writes implementation** → Controllers, logic, UI components
2. **Humans write tests** → Mathematical proofs via property-based tests
3. **Types act as guards** → Go's strict typing + TypeScript prevent many errors
4. **Code review focuses on finance** → Edge cases, precision, balance integrity

**Question for unclear sections?** Ask about specific domains (auth flow, transaction posting, balance sync, etc.) rather than generic patterns.

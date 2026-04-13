---
trigger: glob
globs: *.go
---

**Stack:** Go(GoFrame) backend, PostgreSQL, Redis, RabbitMQ.

**Financial Domain Rules (NON-NEGOTIABLE):**
1. NEVER use float/double for money!
   - Backend MUST use `shopspring/decimal`.
2. Any modification to ledger/balance logic MUST include property-based boundary tests (zero values, negative balances, precision loss).

**Backend Architecture Constraints:**
- Router: `internal/cmd/cmd.go` defines all routes/middleware.
- Controllers (`internal/controller/`): ONLY handle HTTP requests & Protobuf ↔ models conversion.
- Logic (`internal/logic/`): All business logic goes here.
- Boot (`internal/boot/`): Init DB, Redis, RabbitMQ, ALE encryption.
- Security: NEVER bypass auth middleware for admin endpoints.
- Do NOT modify auto-generated files directly (`// DO NOT EDIT`).
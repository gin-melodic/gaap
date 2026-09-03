# Health Checks UAT

> This file only keeps cases within this Beta's scope; non-Beta cases live in `deferred.md`. PASS means the case already passed under UAT, and NOT RUN means it has not been executed yet.

2026-08-13 full retest batch: [`UAT-20260813-BETA-RC-01`](runs/2026-08-13-beta-rc-01.md).

## TC-HEALTH-001 — System Health Check

- Module: Health Checks module / System health check
- Priority: P0
- Execution status: **PASS**
- Execution batch: 2026-08-12 automated UAT; fix retest passed the same day
- Execution environment: local production-mode UAT Docker stack
- Beta disposition: **CORE GATE**
- Preconditions: system running normally
- Test data: none
- Expected result: 1. live returns status code 200
  2. ready returns status code 200 when PostgreSQL, Redis, RabbitMQ and migrations are all healthy
  3. ready returns status code 503 when any core dependency is unavailable

### Steps

1. Call the health check endpoints

### Execution evidence

- With all dependencies healthy: `live` returned HTTP 200 / `{"status":"alive"}` and `ready` returned HTTP 200 / `{"status":"ready"}`.
- Stopping PostgreSQL, Redis or RabbitMQ individually: `ready` returned HTTP 503 / `{"status":"unavailable"}` in each case; with Redis or RabbitMQ stopped, `live` still returned HTTP 200.
- After PostgreSQL and Redis recovered to healthy, `ready` automatically recovered to HTTP 200.
- After RabbitMQ recovered to healthy, `ready` kept returning HTTP 503 until the API was restarted; **FAIL**, see DEF-020.

### 2026-08-12 fix retest evidence

- After stopping RabbitMQ, the API kept running and `ready` returned HTTP 503 / `{"status":"unavailable"}`.
- After restoring RabbitMQ, no API restart was needed; the connection supervisor reconnected automatically via backoff retries, and `ready` recovered to HTTP 200 / `{"status":"ready"}`.
- Both `gaap.tasks` and `gaap.dashboard` re-registered one consumer requiring ACKs each.
- Result: **PASS**; DEF-020 fixed.

## TC-HEALTH-002 — Database Connection Check

- Module: Health Checks module / System health check
- Priority: P0
- Execution status: **PASS**
- Execution batch: 2026-08-12 automated UAT
- Execution environment: local production-mode UAT Docker stack
- Beta disposition: **CORE GATE**
- Preconditions: database running normally
- Test data: none
- Expected result: returns that the database connection status is healthy

### Steps

1. Call the health check endpoints
2. Check the database connection status

### Execution evidence

- With PostgreSQL healthy, `ready` was HTTP 200; after stopping PostgreSQL it dropped to HTTP 503; after restoring PostgreSQL it automatically recovered to HTTP 200; **PASS**.

## TC-HEALTH-003 — Redis Connection Check

- Module: Health Checks module / System health check
- Priority: P0
- Execution status: **PASS**
- Execution batch: 2026-08-12 automated UAT
- Execution environment: local production-mode UAT Docker stack
- Beta disposition: **CORE GATE**
- Preconditions: Redis running normally
- Test data: none
- Expected result: returns that the Redis connection status is healthy

### Steps

1. Call the health check endpoints
2. Check the Redis connection status

### Execution evidence

- With Redis healthy, `ready` was HTTP 200; after stopping Redis it dropped to HTTP 503 while `live` stayed at HTTP 200; after restoring Redis, `ready` automatically recovered to HTTP 200; **PASS**.

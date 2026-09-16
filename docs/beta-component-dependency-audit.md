# Beta Component Dependency Audit

Audit date: 2026-08-12. The judgment criteria are the actual core request chain, startup chain and frontend entry points; whether a component can be removed from the production stack must not be decided based on its feature name alone.

## Conclusions

| Planned Component or Feature | Actual Dependency | Beta Decision | Code Disposition |
|---|---|---|---|
| RabbitMQ | Dashboard snapshot refresh, persistent rebuild | **Keep, core dependency** | Added RabbitMQ to UAT/production Compose; API startup and ready fail closed; start the Dashboard worker |
| WebSocket | Task status push only | Not offered | Production does not bind `/v1/ws`; the frontend task notification hook is unmounted; no compatibility layer needed |
| Task Center | RabbitMQ `gaap.tasks` queue and task APIs | UI/API deferred, but keep existing workers | Beta middleware rejects the task APIs; since RabbitMQ is already a core dependency, keeping an idle worker is simpler than adding runtime-mode branches |
| Import/Export | Task queues, file directories, download endpoints | Not offered | UI hidden and Beta middleware rejects the data APIs; no export file volume mounted |
| Account Migration & Delete | Task queue, migration logic, task center | Not offered | Backend refuses to delete accounts that have business transactions; frontend removes the migration picker and shows a clear notice |
| Pro Account Groups & Sub-Accounts | Pro user tier, parent/child account UI and validation | Not offered | All success-path UAT deferred; the normal UI path is unreachable, but the server must still reject Free users submitting `is_group`/`parent_id` directly — hiding the UI cannot replace authorization checks |
| 2FA | TOTP branch at login | Settings entry not offered | Users in the fresh production DB are all unenrolled; settings/change APIs hidden/rejected; login compatibility code kept without introducing external components |
| Password Change | Auth API | Not offered | No UI entry point, Beta middleware rejects the endpoints; login, refresh and logout do not depend on it |
| Exchange Rates & Multi-Currency Conversion | Browser-side external rate API, frontend rate state | Not offered | Settings entry unreachable; core amounts and Dashboard never read exchange rates, only the user's base currency is allowed |
| Startup Balance Recalculation | PostgreSQL, Redis locks, full accounting rules | **Not run as a startup fixer** | The current implementation has incomplete enumeration and rules; removed from the startup chain; account balances are persisted by transaction transactions, and startup only rebuilds the derived Dashboard data |
| PostgreSQL Dashboard Snapshots | Dashboard cold-start cache | Kept but not source of truth | Transaction/account changes clear both Redis and stale database snapshots at the same time; startup rebuilds from transaction and account data; reviving old snapshots is forbidden |

## Production Architecture Revision

The first production stack should be Caddy, Web, API, PostgreSQL, Redis and RabbitMQ. RabbitMQ exposes no port to the host and sits only on the Docker internal data network. Tasks, import/export and WebSocket remain deferred features, but "deferring these features" is no longer equivalent to "removing RabbitMQ".

The API must not return ready until PostgreSQL, Redis, RabbitMQ and migrations are all available. If the RabbitMQ startup connection fails, the API does not start; if a running connection closes, ready returns 503.

## Still Gated

- Implement a read-only ledger reconciler covering assets, liabilities, income, expenses, equity, opening balances and transfers; when inconsistencies are found it must report them and block release — production balances may not be rewritten automatically.
- Fix the server-side tier validation on account creation and verify with `TC-EDGE-SEC-003` that Free users cannot bypass the UI to create account groups or sub-accounts; this is a Beta permission boundary and is not deferred along with the Pro success paths.
- Verify the API recovery policy after RabbitMQ restarts. Ready currently flips to 503, but the AMQP client lacks complete automatic reconnection and consumer re-registration; as a runbook solution for this week, restarting the API container in tandem is acceptable.
- Manually verify via UAT that after creating, updating or deleting transactions with historical dates, the Dashboard reflects correct dates
  and balance changes within a single page refresh.
- Before production deployment, resolve infrastructure images to verified exact versions or digests to avoid floating-tag drift.

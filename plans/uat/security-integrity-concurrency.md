# Security, Integrity & Concurrency UAT

> This file only keeps cases within this Beta's scope; non-Beta cases live in `deferred.md`. PASS means the case already passed under UAT, and NOT RUN means it has not been executed yet.

2026-08-13 full retest batch: [`UAT-20260813-BETA-RC-01`](runs/2026-08-13-beta-rc-01.md).

## TC-EDGE-CONC-001 — Concurrent Account Creation

- Module: Boundary Conditions & Exception Scenarios / Concurrency and performance tests
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: 10 concurrent requests
- Expected result: all requests are handled correctly with no data conflicts

### Steps

1. Issue multiple create-account requests at the same time

## TC-EDGE-CONC-002 — Concurrent Updates of the Same Transaction

- Module: Boundary Conditions & Exception Scenarios / Concurrency and performance tests
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and a transaction exists
- Test data: same transaction ID, different update contents
- Expected result: concurrency handled correctly with final data consistency

### Steps

1. Issue multiple concurrent requests updating the same transaction

## TC-EDGE-CONC-003 — Concurrent Logins

- Module: Boundary Conditions & Exception Scenarios / Concurrency and performance tests
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is registered
- Test data: the same account with multiple login requests
- Expected result: depending on system design, either multi-device logins are allowed or restricted

### Steps

1. Log in to the same account simultaneously from multiple devices

## TC-EDGE-SEC-001 — SQL Injection Test

- Module: Boundary Conditions & Exception Scenarios / Security tests
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: system running normally
- Test data: name: ' OR '1'='1
- Expected result: the system filters correctly and no SQL injection is executed

### Steps

1. Enter an SQL injection statement in an input field

## TC-EDGE-SEC-002 — XSS Attack Test

- Module: Boundary Conditions & Exception Scenarios / Security tests
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: system running normally
- Test data: note: <script>alert('XSS')</script>
- Expected result: the system escapes correctly and no script is executed

### Steps

1. Enter an XSS script in an input field

## TC-EDGE-SEC-003 — Authorization Bypass Test

- Module: Boundary Conditions & Exception Scenarios / Security tests
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: two different users are logged in; the Beta user tier is Free
- Test data: user A's token and user B's resource IDs; a Free user directly submits `is_group=true` or
  `parent_id`
- Expected result: cross-user resource access is rejected; a Free user cannot bypass the UI to create an account group or sub-account, nor write any account or opening-balance transaction

### Steps

1. User A tries to access user B's accounts or transactions
2. A Free user bypasses the disabled frontend controls and calls the create-account API directly with `is_group=true`
3. A Free user calls the create-account API directly with an arbitrary `parent_id`
4. Verify the requests are rejected and no new records appear in either the accounts or transactions tables

## TC-EDGE-SEC-004 — Expired Token Access

- Module: Boundary Conditions & Exception Scenarios / Security tests
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: the user's token has expired
- Test data: an expired access token
- Expected result: access is rejected with a "token expired" message

### Steps

1. Access a protected resource using the expired token

## TC-EDGE-SEC-005 — Invalid Token Access

- Module: Boundary Conditions & Exception Scenarios / Security tests
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: none
- Test data: a random string used as the token
- Expected result: access is rejected with an "invalid token" message

### Steps

1. Access a protected resource using the invalid token

## TC-EDGE-DATA-001 — Double-Entry Bookkeeping Balance Verification

- Module: Boundary Conditions & Exception Scenarios / Data integrity tests
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and multiple transactions exist
- Test data: none
- Expected result: assets = liabilities + equity

### Steps

1. Verify the sum of all account balances
2. Verify that assets = liabilities + equity

## TC-EDGE-DATA-002 — Balance Consistency After Transaction Deletion

- Module: Boundary Conditions & Exception Scenarios / Data integrity tests
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and transactions exist
- Test data: a valid transaction ID
- Expected result: the balance rolls back correctly and data remains consistent

### Steps

1. Record the account balances before deletion
2. Delete the transaction
3. Verify the account balances rolled back correctly

## TC-EDGE-DATA-003 — Balance Consistency After Transaction Update

- Module: Boundary Conditions & Exception Scenarios / Data integrity tests
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and transactions exist
- Test data: a valid transaction ID, a new amount
- Expected result: the balance adjusts correctly and data remains consistent

### Steps

1. Record the account balances before the update
2. Update the transaction amount
3. Verify the account balances adjusted correctly

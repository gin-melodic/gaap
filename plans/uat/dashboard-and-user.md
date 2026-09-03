# Dashboard, Settings & User UAT

> This file only keeps cases within this Beta's scope; non-Beta cases live in `deferred.md`. PASS means the case already passed under UAT, and NOT RUN means it has not been executed yet.

2026-08-13 full retest batch: [`UAT-20260813-BETA-RC-01`](runs/2026-08-13-beta-rc-01.md).

## TC-DASH-SUMMARY-001 — Get Dashboard Summary Data

- Module: Dashboard module / Dashboard summary
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and account/transaction data exists
- Test data: none
- Expected result: 1. Returns the total asset amount
  2. Returns the total liability amount
  3. Returns the net-worth amount

### Steps

1. Call the dashboard summary API

## TC-DASH-SUMMARY-002 — Dashboard Summary With No Data

- Module: Dashboard module / Dashboard summary
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in with no account/transaction data
- Test data: none
- Expected result: assets, liabilities and net worth are all returned as 0

### Steps

1. Call the dashboard summary API

## TC-DASH-MONTHLY-001 — Get Monthly Income/Expense Statistics

- Module: Dashboard module / Monthly statistics
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and transaction data exists
- Test data: none
- Expected result: 1. Returns the total income for the current calendar month
  2. Returns the total expense for the current calendar month
  3. Amounts are denominated in the user's registration base currency

### Steps

1. Call the monthly statistics API

## TC-DASH-TREND-001 — Get Balance Trend Data

- Module: Dashboard module / Balance trend
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and historical transaction data exists
- Test data: none
- Expected result: 1. Returns daily balance data for the last 30 days
  2. Data includes dates and account balances in the user's base currency
  3. Historical-date transactions are reflected in that day's end-of-day balance

### Steps

1. Call the balance trend API

## TC-CFG-CURR-001 — Get Supported Currency List

- Module: Configuration module / Currency management
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: none
- Expected result: returns the list of all currencies supported by the system

### Steps

1. Call the currency list API

## TC-CFG-ACCTTYPE-001 — Get Account Type Definitions

- Module: Configuration module / Account type management
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: none
- Expected result: returns all account type definitions: ASSET LIABILITY INCOME EXPENSE EQUITY

### Steps

1. Call the account type API

## TC-USER-PROFILE-001 — Get Current User Profile

- Module: User management module / User profile
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: none
- Expected result: 1. Returns the user's ID, email address, nickname and other info
  2. Returns the user tier type

### Steps

1. Call the user profile API

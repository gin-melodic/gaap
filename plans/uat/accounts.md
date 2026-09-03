# Accounts UAT

> This file only keeps cases within this Beta's scope; non-Beta cases live in `deferred.md`. PASS means the case already passed under UAT, and NOT RUN means it has not been executed yet.

2026-08-13 full retest batch: [`UAT-20260813-BETA-RC-01`](runs/2026-08-13-beta-rc-01.md).

## TC-ACCT-LIST-001 — Query Full Account List

- Module: Account management module / Account list query
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and account data exists
- Test data: no filter conditions
- Expected result: 1. Returns the full account list
  2. Includes account ID, name, type, balance, etc.
  3. Supports pagination

### Steps

1. Call the account list API
2. Do not add any filter conditions

## TC-ACCT-LIST-002 — Filter by Account Type

- Module: Account management module / Account list query
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and accounts of different types exist
- Test data: account type: ASSET
- Expected result: only asset-type accounts are returned

### Steps

1. Call the account list API
2. Specify an account-type filter condition

## TC-ACCT-LIST-003 — Empty Account List

- Module: Account management module / Account list query
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in with no account data
- Test data: none
- Expected result: an empty list is returned without errors

### Steps

1. Call the account list API

## TC-ACCT-CREATE-001 — Create an Asset Account

- Module: Account management module / Create account
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: name: Cash Account, type: ASSET, initial balance: 1000.00 CNY, date: 2026-01-01
- Expected result: 1. Creation succeeds
  2. The account ID is returned
  3. The account balance displays correctly

### Steps

1. Call the create-account API
2. Fill in the account information

## TC-ACCT-CREATE-002 — Create a Liability Account

- Module: Account management module / Create account
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: name: Credit Card, type: LIABILITY, initial balance: -5000.00 CNY
- Expected result: 1. Creation succeeds
  2. The liability balance displays correctly as negative or positive (depending on system design)

### Steps

1. Call the create-account API
2. Fill in the liability account information

## TC-ACCT-CREATE-005 — Create Account - Missing Required Field

- Module: Account management module / Create account
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: name: empty, type: ASSET
- Expected result: creation fails with a "missing required field" message

### Steps

1. Call the create-account API
2. Leave the account name unfilled

## TC-ACCT-CREATE-006 — Create Account - Invalid Account Type

- Module: Account management module / Create account
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: name: Test Account, type: 999
- Expected result: creation fails with an "invalid account type" message

### Steps

1. Call the create-account API
2. Specify an invalid account type

## TC-ACCT-CREATE-007 — Create Account - Zero Initial Balance

- Module: Account management module / Create account
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: name: New Account, type: ASSET, initial balance: 0
- Expected result: creation succeeds and the balance displays as 0

### Steps

1. Call the create-account API
2. Set the initial balance to 0

## TC-ACCT-CREATE-008 — Create Account - Negative Initial Balance for Asset Account

- Module: Account management module / Create account
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: name: Overdraft Account, type: ASSET, initial balance: -100.00
- Expected result: depending on system design, creation may succeed or an error may be shown

### Steps

1. Call the create-account API
2. Set a negative initial balance for the asset account

## TC-ACCT-GET-001 — Get Details of an Existing Account

- Module: Account management module / Get account details
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the account exists
- Test data: a valid account ID
- Expected result: 1. Returns complete account information
  2. Includes ID, name, type, balance, created time, etc.

### Steps

1. Call the get-account-details API
2. Pass in a valid account ID

## TC-ACCT-GET-002 — Get Details of a Nonexistent Account

- Module: Account management module / Get account details
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: a nonexistent account ID
- Expected result: an error is returned stating the account does not exist

### Steps

1. Call the get-account-details API
2. Pass in a nonexistent account ID

## TC-ACCT-UPDATE-001 — Update Account Name

- Module: Account management module / Update account
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the account exists
- Test data: account ID: a valid ID, new name: Updated Account Name
- Expected result: 1. The update succeeds
  2. The account name has changed

### Steps

1. Call the update-account API
2. Change the account name

## TC-ACCT-UPDATE-002 — Update Account Note

- Module: Account management module / Update account
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the account exists
- Test data: account ID: a valid ID, note: This is the note content
- Expected result: the update succeeds and the note has been added/modified

### Steps

1. Call the update-account API
2. Add or modify the note

## TC-ACCT-UPDATE-003 — Update a Nonexistent Account

- Module: Account management module / Update account
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: account ID: a nonexistent ID, name: New Name
- Expected result: the update fails with an "account does not exist" message

### Steps

1. Call the update-account API
2. Pass in a nonexistent account ID

## TC-ACCT-DELETE-001 — Delete an Account With No Transactions

- Module: Account management module / Delete account
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the account exists with no linked transactions
- Test data: the ID of an account with no transactions
- Expected result: 1. Deletion succeeds
  2. The account is removed from the list

### Steps

1. Call the delete-account API
2. Pass in the account ID

## TC-ACCT-COUNT-001 — Get Account Transaction Count

- Module: Account management module / Get account transaction count
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the account exists with transactions
- Test data: a valid account ID
- Expected result: returns the number of linked transactions for this account

### Steps

1. Call the get-transaction-count API
2. Pass in the account ID

## TC-ACCT-COUNT-002 — Get Transaction Count of an Account With No Transactions

- Module: Account management module / Get account transaction count
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the account exists but has no transactions
- Test data: the ID of an account with no transactions
- Expected result: returns a transaction count of 0

### Steps

1. Call the get-transaction-count API
2. Pass in the ID of an account with no transactions

## TC-EDGE-ACCT-001 — Extremely Large Balance Amount

- Module: Boundary Conditions & Exception Scenarios / Account boundary tests
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: balance: 999999999999999999.99
- Expected result: depending on system precision, it may succeed or show an amount-exceeded error

### Steps

1. Set an extremely large balance when creating the account

## TC-EDGE-ACCT-002 — Overly Long Account Name

- Module: Boundary Conditions & Exception Scenarios / Account boundary tests
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: name: an account name of more than 100 characters
- Expected result: creation fails with a "name length exceeded" message

### Steps

1. Enter an overly long name when creating the account

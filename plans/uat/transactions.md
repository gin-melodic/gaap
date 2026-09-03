# Transactions UAT

> This file only keeps cases within this Beta's scope; non-Beta cases live in `deferred.md`. PASS means the case already passed under UAT, and NOT RUN means it has not been executed yet.

2026-08-13 full retest batch: [`UAT-20260813-BETA-RC-01`](runs/2026-08-13-beta-rc-01.md).

## TC-TXN-LIST-001 — Query Full Transaction List

- Module: Transaction management module / Transaction list query
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and transaction data exists
- Test data: no filter conditions
- Expected result: 1. Returns the full transaction list
  2. Includes transaction ID, date, amount, type, etc.
  3. Supports pagination

### Steps

1. Call the transaction list API
2. Do not add any filter conditions

## TC-TXN-LIST-002 — Filter Transactions by Date Range

- Module: Transaction management module / Transaction list query
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and transaction data exists
- Test data: start date: 2026-01-01, end date: 2026-01-31
- Expected result: only transactions within the specified date range are returned

### Steps

1. Call the transaction list API
2. Specify start and end dates

## TC-TXN-LIST-003 — Filter Transactions by Account

- Module: Transaction management module / Transaction list query
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and transaction data exists
- Test data: account ID: a valid account ID
- Expected result: only transactions related to that account are returned

### Steps

1. Call the transaction list API
2. Specify an account ID

## TC-TXN-LIST-004 — Filter by Transaction Type

- Module: Transaction management module / Transaction list query
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and transactions of different types exist
- Test data: transaction type: INCOME
- Expected result: only income-type transactions are returned

### Steps

1. Call the transaction list API
2. Specify a transaction type

## TC-TXN-LIST-005 — Transaction List Sorting - Date Descending

- Module: Transaction management module / Transaction list query
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and transaction data exists
- Test data: sort field: date, sort direction: desc
- Expected result: transactions are ordered by date from newest to oldest

### Steps

1. Call the transaction list API
2. Specify descending-by-date sorting

## TC-TXN-LIST-006 — Paginated Transaction Query

- Module: Transaction management module / Transaction list query
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and there are many transactions
- Test data: page number: 1, page size: 10
- Expected result: 1. Returns the first page with 10 transactions
  2. Returns total count and total pages information

### Steps

1. Call the transaction list API
2. Specify page number and page size

## TC-TXN-CREATE-001 — Create an Income Transaction

- Module: Transaction management module / Create transaction
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and both an income account and an asset account exist
- Test data: date: 2026-01-15, from account: income account, to account: asset account, amount: 5000.00 CNY, type: INCOME, note: Salary income
- Expected result: 1. Creation succeeds
  2. Returns the transaction ID
  3. The asset account balance increases
- Calculation/verification: asset_old + 5000 = asset_new; income_old - 5000 = income_new

### Steps

1. Call the create-transaction API
2. Fill in the income transaction information

## TC-TXN-CREATE-002 — Create an Expense Transaction

- Module: Transaction management module / Create transaction
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and both an expense account and an asset account exist
- Test data: date: 2026-01-16, from account: asset account, to account: expense account, amount: 100.00 CNY, type: EXPENSE, note: Dining expense
- Expected result: 1. Creation succeeds
  2. The asset account balance decreases
- Calculation/verification: asset_old - 100 = asset_new; expense_old + 100 = expense_new

### Steps

1. Call the create-transaction API
2. Fill in the expense transaction information

## TC-TXN-CREATE-003 — Create a Transfer Transaction

- Module: Transaction management module / Create transaction
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and two asset accounts exist
- Test data: date: 2026-01-17, from account: Account A, to account: Account B, amount: 1000.00 CNY, type: TRANSFER, note: Inter-account transfer
- Expected result: 1. Creation succeeds
  2. Account A's balance decreases
  3. Account B's balance increases
- Calculation/verification: assetA_old - 1000 = assetA_new; assetB_old + 1000 = assetB_new

### Steps

1. Call the create-transaction API
2. Fill in the transfer transaction information

## TC-TXN-CREATE-004 — Create Transaction - Zero Amount

- Module: Transaction management module / Create transaction
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: amount: 0
- Expected result: depending on system design, creation may succeed or an invalid-amount error may be shown

### Steps

1. Call the create-transaction API
2. Set the amount to 0

## TC-TXN-CREATE-005 — Create Transaction - Negative Amount

- Module: Transaction management module / Create transaction
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: amount: -100.00
- Expected result: depending on system design, it may be rejected or automatically absolved to a positive value

### Steps

1. Call the create-transaction API
2. Set a negative amount

## TC-TXN-CREATE-006 — Create Transaction - Nonexistent Account

- Module: Transaction management module / Create transaction
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: from account: a nonexistent ID
- Expected result: creation fails with an "account does not exist" message

### Steps

1. Call the create-transaction API
2. Use a nonexistent account ID

## TC-TXN-CREATE-007 — Create Transaction - Transfer Between Same Account

- Module: Transaction management module / Create transaction
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: from account: Account A, to account: Account A
- Expected result: depending on system design, it may be rejected or allowed

### Steps

1. Call the create-transaction API
2. Use the same account for source and target

## TC-TXN-CREATE-008 — Create Transaction - Future Date

- Module: Transaction management module / Create transaction
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: date: 2027-01-01
- Expected result: creation succeeds and the transaction is recorded with a future date

### Steps

1. Call the create-transaction API
2. Set a future date

## TC-TXN-CREATE-009 — Create Transaction - Minimal Amount

- Module: Transaction management module / Create transaction
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: amount: 0.001 CNY
- Expected result: depending on the system's precision design, it may be rounded or rejected

### Steps

1. Call the create-transaction API
2. Set a minimal amount

## TC-TXN-CREATE-010 — Create Transaction - Large Amount

- Module: Transaction management module / Create transaction
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: amount: 999999999999.99 CNY
- Expected result: creation succeeds and the amount is recorded correctly

### Steps

1. Call the create-transaction API
2. Set a large amount

## TC-TXN-GET-001 — Get Details of an Existing Transaction

- Module: Transaction management module / Get transaction details
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the transaction exists
- Test data: a valid transaction ID
- Expected result: 1. Returns complete transaction information
  2. Includes ID, date, amount, type, accounts, etc.

### Steps

1. Call the get-transaction-details API
2. Pass in a valid transaction ID

## TC-TXN-GET-002 — Get Details of a Nonexistent Transaction

- Module: Transaction management module / Get transaction details
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: a nonexistent transaction ID
- Expected result: an error is returned stating the transaction does not exist

### Steps

1. Call the get-transaction-details API
2. Pass in a nonexistent transaction ID

## TC-TXN-UPDATE-001 — Update Transaction Amount

- Module: Transaction management module / Update transaction
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the transaction exists
- Test data: transaction ID: a valid ID, new amount: 200.00
- Expected result: 1. The update succeeds
  2. Related account balances are adjusted automatically
- Calculation/verification: adjustment = new amount - old amount

### Steps

1. Call the update-transaction API
2. Change the transaction amount

## TC-TXN-UPDATE-002 — Update Transaction Date

- Module: Transaction management module / Update transaction
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the transaction exists
- Test data: transaction ID: a valid ID, new date: 2026-01-20
- Expected result: the update succeeds and the transaction date has changed

### Steps

1. Call the update-transaction API
2. Change the transaction date

## TC-TXN-UPDATE-003 — Update Transaction Note

- Module: Transaction management module / Update transaction
- Priority: P1
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the transaction exists
- Test data: transaction ID: a valid ID, new note: Updated Note
- Expected result: the update succeeds and the note has changed

### Steps

1. Call the update-transaction API
2. Change the transaction note

## TC-TXN-UPDATE-004 — Update Transaction Account

- Module: Transaction management module / Update transaction
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the transaction exists
- Test data: transaction ID: a valid ID, new source account: another account ID
- Expected result: 1. The update succeeds
  2. The original account balance rolls back
  3. The new account balance updates

### Steps

1. Call the update-transaction API
2. Change the source or target account

## TC-TXN-DELETE-001 — Delete an Existing Transaction

- Module: Transaction management module / Delete transaction
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in and the transaction exists
- Test data: a valid transaction ID
- Expected result: 1. Deletion succeeds
  2. Related account balances roll back automatically

### Steps

1. Call the delete-transaction API
2. Pass in the transaction ID

## TC-TXN-DELETE-002 — Delete a Nonexistent Transaction

- Module: Transaction management module / Delete transaction
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: a nonexistent transaction ID
- Expected result: deletion fails with a "transaction does not exist" message

### Steps

1. Call the delete-transaction API
2. Pass in a nonexistent transaction ID

## TC-EDGE-TXN-001 — Extremely Small Precision Amount Transaction

- Module: Boundary Conditions & Exception Scenarios / Transaction boundary tests
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: amount: 0.0001 CNY
- Expected result: handled according to the currency precision design

### Steps

1. Create a transaction with an extremely small precision amount

## TC-EDGE-TXN-002 — Very Old Date Transaction

- Module: Boundary Conditions & Exception Scenarios / Transaction boundary tests
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: date: 1900-01-01
- Expected result: depending on system design, it may succeed or be rejected

### Steps

1. Create a transaction with a very old date

## TC-EDGE-TXN-003 — Overly Long Transaction Note

- Module: Boundary Conditions & Exception Scenarios / Transaction boundary tests
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: user is logged in
- Test data: note: note content of more than 1000 characters
- Expected result: creation fails or the note is truncated automatically

### Steps

1. Enter an overly long note when creating the transaction

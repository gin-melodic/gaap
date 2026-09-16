# GAAP Beta Deferred Test Cases

This file centrally stores all test cases that do not belong to the scope of the 2026-08-14 invite-only Beta. All cases remain
`NOT RUN / DEFERRED`; they must not be counted toward this release's pass rate, and they must not be duplicated in the original module's Beta case documents.

Deferred scope: 2FA, Pro account groups & sub-accounts, account migration delete, multi-level nested accounts, currency and theme management,
user profile changes, data import/export, and the task center.

- Total deferred cases: 38
- Authentication & 2FA: 7
- Accounts: 6
- Dashboard, Settings & User: 10
- Data & Tasks: 15

## Authentication

### TC-AUTH-LOGIN-004 — Login With 2FA Enabled - No Verification Code

- Module: Auth module / User login
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: the user has two-factor authentication enabled
- Test data: email: 2fauser@example.com, password: Test@123456, verification code: empty
- Expected result: login fails with a message that a 2FA verification code is required

#### Steps

1. Visit the login page
2. Enter the correct email and password
3. Leave the 2FA code empty
4. Click the login button

### TC-AUTH-LOGIN-005 — Login With 2FA Enabled - Correct Code

- Module: Auth module / User login
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: the user has two-factor authentication enabled
- Test data: email: 2fauser@example.com, password: Test@123456, verification code: a correct TOTP code
- Expected result: login succeeds and returns tokens plus user information

#### Steps

1. Visit the login page
2. Enter the correct email and password
3. Enter a correct 2FA code
4. Click the login button

### TC-AUTH-LOGIN-006 — Login With 2FA Enabled - Wrong Code

- Module: Auth module / User login
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: the user has two-factor authentication enabled
- Test data: email: 2fauser@example.com, password: Test@123456, verification code: 000000
- Expected result: login fails with a wrong-verification-code message

#### Steps

1. Visit the login page
2. Enter the correct email and password
3. Enter a wrong 2FA code
4. Click the login button

### TC-AUTH-2FA-001 — Generate 2FA Secret

- Module: Auth module / Two-factor authentication management
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and 2FA is not enabled
- Test data: a valid access token
- Expected result: 1. Returns the 2FA secret key
  2. Returns a QR code URL or Base64 image
  3. Returns backup recovery codes
- Calculation/verification: 2FA skipped

#### Steps

1. Open the security settings page
2. Click enable 2FA
3. Call the generate-2FA-secret API

### TC-AUTH-2FA-002 — Enable 2FA - Correct Code

- Module: Auth module / Two-factor authentication management
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: the user has generated a 2FA secret
- Test data: a correct TOTP code
- Expected result: 2FA is enabled successfully
- Calculation/verification: 2FA skipped

#### Steps

1. Scan the QR code with an authenticator app
2. Enter the current TOTP code
3. Click confirm to enable

### TC-AUTH-2FA-003 — Enable 2FA - Wrong Code

- Module: Auth module / Two-factor authentication management
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: the user has generated a 2FA secret
- Test data: a wrong TOTP code
- Expected result: enabling fails with a wrong-verification-code message
- Calculation/verification: 2FA skipped

#### Steps

1. Enter a wrong TOTP code
2. Click confirm to enable

### TC-AUTH-2FA-004 — Disable 2FA - Logged-in User

- Module: Auth module / Two-factor authentication management
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and 2FA is enabled
- Test data: a correct TOTP code
- Expected result: 2FA is disabled successfully
- Calculation/verification: 2FA skipped

#### Steps

1. Open the security settings page
2. Click disable 2FA
3. Enter the current TOTP code to confirm

## Accounts

### TC-ACCT-CREATE-003 — Create an Account Group

- Module: Account management module / Create account
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Deferral reason: account groups are a Pro feature; this Beta does not provide Pro users, so the normal product path is unreachable.
- Preconditions: user is logged in and is a Pro user
- Test data: name: Bank Accounts, type: ASSET, is group: true
- Expected result: 1. Creation succeeds
  2. The account group can hold sub-accounts

#### Steps

1. Call the create-account API
2. Set it as an account group

### TC-ACCT-CREATE-004 — Create a Sub-Account

- Module: Account management module / Create account
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Deferral reason: sub-accounts depend on Pro account groups; this Beta does not provide Pro users.
- Preconditions: a Pro user is logged in and a parent group exists
- Test data: name: ICBC, type: ASSET, parent account ID: the parent group's ID
- Expected result: 1. Creation succeeds
  2. The sub-account is correctly linked to the parent group

#### Steps

1. Call the create-account API
2. Specify a parent account ID

### TC-ACCT-DELETE-002 — Delete an Account With Transactions - No Migration

- Module: Account management module / Delete account
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the account exists with linked transactions
- Test data: the ID of an account with transactions, migration target: none
- Expected result: depending on system design, deletion may be rejected or the account plus its linked transactions may be deleted

#### Steps

1. Call the delete-account API
2. Do not specify a migration target account

### TC-ACCT-DELETE-003 — Delete an Account With Transactions - Migrate to Another Account

- Module: Account management module / Delete account
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in, the account exists with linked transactions, and a target account exists
- Test data: the ID of an account with transactions, migration target: another valid account ID
- Expected result: 1. Deletion succeeds
  2. The original account's transactions are migrated to the target account

#### Steps

1. Call the delete-account API
2. Specify a migration target account

### TC-ACCT-DELETE-004 — Delete an Account Group - With Sub-Accounts

- Module: Account management module / Delete account
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the account group exists with sub-accounts
- Test data: the ID of an account group with sub-accounts
- Expected result: depending on system design, deletion may be rejected or sub-accounts may be cascade-deleted

#### Steps

1. Call the delete-account API
2. Pass in the account group ID

### TC-EDGE-ACCT-003 — Multi-Level Nested Account Groups

- Module: Boundary Conditions & Exception Scenarios / Account boundary tests
- Priority: P2
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in
- Test data: create account-group nesting deeper than 10 levels
- Expected result: depending on system design, it may succeed or the nesting depth may be limited

#### Steps

1. Create a multi-level nested account group structure

## Dashboard, Settings & User

### TC-DASH-MONTHLY-002 — Get Statistics for a Specified Month

- Module: Dashboard module / Monthly statistics
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Deferral reason: the Beta only provides the current-month overview, and the protocol does not accept year or month parameters.
- Preconditions: user is logged in and transaction data exists
- Test data: year: 2026, month: 1
- Expected result: returns income/expense statistics for January 2026

#### Steps

1. Call the monthly statistics API
2. Specify the year and month

### TC-DASH-TREND-002 — Get Balance Trend for a Specified Date Range

- Module: Dashboard module / Balance trend
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Deferral reason: the Beta always shows the last 30 days of trends, and the protocol only accepts account filters, not date ranges.
- Preconditions: user is logged in and historical transaction data exists
- Test data: start date: 2026-01-01, end date: 2026-01-31
- Expected result: returns balance trend data for the specified date range

#### Steps

1. Call the balance trend API
2. Specify start and end dates

### TC-CFG-CURR-002 — Add a Supported Currency

- Module: Configuration module / Currency management
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in with admin permission
- Test data: currency code: JPY
- Expected result: adding succeeds and the currency appears in the list

#### Steps

1. Call the add-currency API
2. Specify the currency code

### TC-CFG-CURR-003 — Add an Existing Currency

- Module: Configuration module / Currency management
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the currency already exists
- Test data: currency code: CNY
- Expected result: adding fails with a "currency already exists" message

#### Steps

1. Call the add-currency API
2. Specify an existing currency code

### TC-CFG-CURR-004 — Delete a Supported Currency

- Module: Configuration module / Currency management
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in, the currency exists and no accounts are linked to it
- Test data: currency code: JPY
- Expected result: deletion succeeds and the currency is removed from the list

#### Steps

1. Call the delete-currency API
2. Specify the currency code

### TC-CFG-CURR-005 — Delete a Currency in Use by Accounts

- Module: Configuration module / Currency management
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in, the currency exists and accounts use it
- Test data: currency code: CNY
- Expected result: deletion fails with a "currency is in use" message

#### Steps

1. Call the delete-currency API
2. Specify a currency code that is used by accounts

### TC-CFG-THEME-001 — Get Available Theme List

- Module: Configuration module / Theme management
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in
- Test data: none
- Expected result: returns the list of all themes supported by the system

#### Steps

1. Call the get-theme-list API

### TC-USER-PROFILE-002 — Update User Profile

- Module: User management module / User profile
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in
- Test data: new nickname: Test User
- Expected result: the update succeeds and the profile has changed

#### Steps

1. Call the update-user-profile API
2. Change the nickname, etc.

### TC-USER-THEME-001 — Update User Theme Preference

- Module: User management module / Theme preference
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in
- Test data: theme ID: dark
- Expected result: 1. The update succeeds
  2. The UI switches to dark mode

#### Steps

1. Call the update-theme API
2. Specify a theme ID

### TC-USER-THEME-002 — Update to a Nonexistent Theme

- Module: User management module / Theme preference
- Priority: P2
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in
- Test data: theme ID: nonexistent_theme
- Expected result: the update fails with a "theme does not exist" message

#### Steps

1. Call the update-theme API
2. Specify a nonexistent theme ID

## Data, Tasks & Health Checks

### TC-DATA-EXPORT-001 — Create a Data Export Task

- Module: Data import/export module / Data export
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and data exists
- Test data: none
- Expected result: 1. Returns the task ID
  2. The task status is in progress or pending

#### Steps

1. Call the create-export-task API

### TC-DATA-EXPORT-002 — Create an Export Task for a Specified Date Range

- Module: Data import/export module / Data export
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and data exists
- Test data: start date: 2026-01-01, end date: 2026-01-31
- Expected result: returns the task ID, and the exported data contains only the specified range

#### Steps

1. Call the create-export-task API
2. Specify a date range

### TC-DATA-EXPORT-003 — Get Export Task Status

- Module: Data import/export module / Data export
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and an export task exists
- Test data: a valid task ID
- Expected result: returns the task status — in progress, completed or failed

#### Steps

1. Call the get-export-status API
2. Pass in the task ID

### TC-DATA-EXPORT-004 — Download an Exported File

- Module: Data import/export module / Data export
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the export task has completed
- Test data: the ID of a completed task
- Expected result: 1. Returns the exported file content
  2. The file format is correct (e.g., JSON or CSV)

#### Steps

1. Call the download-export-file API
2. Pass in the task ID

### TC-DATA-EXPORT-005 — Download an Incomplete Export File

- Module: Data import/export module / Data export
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the export task is in progress
- Test data: the ID of an in-progress task
- Expected result: download fails with a "task not yet completed" message

#### Steps

1. Call the download-export-file API
2. Pass in the ID of an in-progress task

### TC-DATA-IMPORT-001 — Create a Data Import Task

- Module: Data import/export module / Data import
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and has a valid import file
- Test data: a valid JSON-format export file
- Expected result: 1. Returns the task ID
  2. The task starts processing

#### Steps

1. Call the create-import-task API
2. Upload the import file

### TC-DATA-IMPORT-002 — Import a File With an Invalid Format

- Module: Data import/export module / Data import
- Priority: P0
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in
- Test data: a file with an invalid format
- Expected result: the import fails with an "invalid file format" message

#### Steps

1. Call the create-import-task API
2. Upload a file with an invalid format

### TC-DATA-IMPORT-003 — Import an Empty File

- Module: Data import/export module / Data import
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in
- Test data: an empty file
- Expected result: the import fails with a "file is empty or invalid" message

#### Steps

1. Call the create-import-task API
2. Upload an empty file

### TC-DATA-IMPORT-004 — Import a Large File

- Module: Data import/export module / Data import
- Priority: P2
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in
- Test data: an import file over 10MB
- Expected result: depending on system limits, it may succeed or show a "file too large" message

#### Steps

1. Call the create-import-task API
2. Upload a large file

### TC-TASK-LIST-001 — Get Task List

- Module: Task management module / Task list
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and tasks exist
- Test data: none
- Expected result: 1. Returns the full task list
  2. Includes task ID, type, status, etc.

#### Steps

1. Call the task list API

### TC-TASK-GET-001 — Get Task Details

- Module: Task management module / Task details
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the task exists
- Test data: a valid task ID
- Expected result: returns complete task information including progress and error details

#### Steps

1. Call the get-task-details API
2. Pass in the task ID

### TC-TASK-CANCEL-001 — Cancel an In-Progress Task

- Module: Task management module / Task operations
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the task is in progress
- Test data: the ID of an in-progress task
- Expected result: 1. The task is cancelled successfully
  2. The task status becomes cancelled

#### Steps

1. Call the cancel-task API
2. Pass in the task ID

### TC-TASK-CANCEL-002 — Cancel a Completed Task

- Module: Task management module / Task operations
- Priority: P2
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the task has completed
- Test data: the ID of a completed task
- Expected result: cancellation fails with a "task already completed, cannot be cancelled" message

#### Steps

1. Call the cancel-task API
2. Pass in the ID of a completed task

### TC-TASK-RETRY-001 — Retry a Failed Task

- Module: Task management module / Task operations
- Priority: P1
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the task failed
- Test data: the ID of a failed task
- Expected result: 1. The task starts running again
  2. The task status becomes in progress

#### Steps

1. Call the retry-task API
2. Pass in the ID of the failed task

### TC-TASK-RETRY-002 — Retry a Successful Task

- Module: Task management module / Task operations
- Priority: P2
- Execution status: **NOT RUN**
- Beta disposition: **DEFERRED**
- Preconditions: user is logged in and the task succeeded
- Test data: the ID of a successful task
- Expected result: retry fails with a "task already succeeded, no need to retry" message

#### Steps

1. Call the retry-task API
2. Pass in the ID of the successful task

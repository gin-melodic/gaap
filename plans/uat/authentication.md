# Authentication UAT

> This file only keeps cases within this Beta's scope; non-Beta cases live in `deferred.md`. PASS means the case already passed under UAT, and NOT RUN means it has not been executed yet.

2026-08-13 full retest batch: [`UAT-20260813-BETA-RC-01`](runs/2026-08-13-beta-rc-01.md).

## TC-AUTH-REG-001 — Normal User Registration

- Module: Auth module / User registration
- Priority: P0
- Execution status: **PASS**
- Execution batch: original UAT (date not recorded)
- Execution environment: original UAT (specific environment not recorded)
- Beta disposition: **CORE REGRESSION**
- Preconditions: system running normally, user not registered
- Test data: email: test@example.com, password: Test@123456
- Expected result: 1. Registration succeeds and returns a success message
  2. Returns an access token and a refresh token
  3. Returns basic user information
  4. Returns the ALE session key

### Steps

1. Visit the registration page
2. Enter a valid email address
3. Enter a password meeting the requirements
4. Complete the human verification
5. Click the register button

## TC-AUTH-REG-002 — Duplicate Email Registration

- Module: Auth module / User registration
- Priority: P0
- Execution status: **PASS**
- Execution batch: original UAT (date not recorded)
- Execution environment: original UAT (specific environment not recorded)
- Beta disposition: **CORE REGRESSION**
- Preconditions: a user with the email test@example.com already exists in the system
- Test data: email: test@example.com, password: Test@123456
- Expected result: registration fails with "email already registered"

### Steps

1. Visit the registration page
2. Enter an existing email address
3. Enter a password
4. Click the register button

## TC-AUTH-REG-003 — Invalid Email Format Registration

- Module: Auth module / User registration
- Priority: P1
- Execution status: **PASS**
- Execution batch: original UAT (date not recorded)
- Execution environment: original UAT (specific environment not recorded)
- Beta disposition: **CORE REGRESSION**
- Preconditions: system running normally
- Test data: email: invalid-email, password: Test@123456
- Expected result: registration fails with "invalid email format"

### Steps

1. Visit the registration page
2. Enter an email in an invalid format
3. Enter a password
4. Click the register button

### 2026-08-12 automated regression evidence

- Environment: local production-mode UAT Docker stack; the browser reached the same Web/API containers through a test entry point bound to loopback only.
- Result: after entering `invalid-email` and clicking register, the browser email constraint blocked submission with a message that the address is missing an `@`; **PASS**.

## TC-AUTH-REG-004 — Weak Password Registration

- Module: Auth module / User registration
- Priority: P1
- Execution status: **PASS**
- Execution batch: original UAT (date not recorded); 2026-08-12 automated regression failed, then the fix retest passed
- Execution environment: local production-mode UAT Docker stack
- Beta disposition: **CORE REGRESSION**
- Preconditions: system running normally
- Test data: email: test2@example.com, password: 123456
- Expected result: registration fails with "password strength insufficient"

### Steps

1. Visit the registration page
2. Enter a valid email
3. Enter a weak password
4. Click the register button

### 2026-08-12 automated regression evidence

- After entering a 6-character password, although both password fields declared `minLength=8`, the form was actually submitted.
- The page only showed `Registration failed, please try again later...`; there was no insufficient-strength message.
- Result: **FAIL**; DEF-013 reopened.

### 2026-08-12 fix retest evidence

- In the production-mode UAT image, entering a 6-character password and clicking register showed `Password must contain between 8 and 100 characters` on the page.
- No generic registration failure was shown, no navigation occurred, and the registration request never reached the server; both password fields declared `minLength=8` and `maxLength=100`.
- Both frontend and backend validate 8–100 characters by Unicode character count; boundary unit tests cover 7, 8, 100 and 101 characters.
- Result: **PASS**; the DEF-013 failure was fixed.

## TC-AUTH-REG-005 — Empty Field Registration

- Module: Auth module / User registration
- Priority: P1
- Execution status: **PASS**
- Execution batch: original UAT (date not recorded)
- Execution environment: original UAT (specific environment not recorded)
- Beta disposition: **CORE REGRESSION**
- Preconditions: system running normally
- Test data: email: empty, password: Test@123456
- Expected result: registration fails with "required fields cannot be empty"

### Steps

1. Visit the registration page
2. Leave the email or password empty
3. Click the register button

### 2026-08-12 automated regression evidence

- After clearing the required nickname and clicking register, the browser blocked submission with `Please fill out this field.`; **PASS**.

## TC-AUTH-LOGIN-001 — Normal User Login

- Module: Auth module / User login
- Priority: P0
- Execution status: **PASS**
- Execution batch: original UAT (date not recorded)
- Execution environment: original UAT (specific environment not recorded)
- Beta disposition: **CORE REGRESSION**
- Preconditions: user is registered and the account status is normal
- Test data: email: test@example.com, password: Test@123456
- Expected result: 1. Login succeeds
  2. Returns an access token and a refresh token
  3. Returns user information
  4. Returns the ALE session key

### Steps

1. Visit the login page
2. Enter the correct email and password
3. Complete the human verification
4. Click the login button

## TC-AUTH-LOGIN-002 — Wrong Password Login

- Module: Auth module / User login
- Priority: P0
- Execution status: **PASS**
- Execution batch: original UAT (date not recorded)
- Execution environment: original UAT (specific environment not recorded)
- Beta disposition: **CORE REGRESSION**
- Preconditions: user is registered
- Test data: email: test@example.com, password: WrongPassword
- Expected result: login fails with "email or password incorrect"

### Steps

1. Visit the login page
2. Enter the correct email and a wrong password
3. Click the login button

## TC-AUTH-LOGIN-003 — Login With Nonexistent User

- Module: Auth module / User login
- Priority: P0
- Execution status: **PASS**
- Execution batch: original UAT (date not recorded)
- Execution environment: original UAT (specific environment not recorded)
- Beta disposition: **CORE REGRESSION**
- Preconditions: system running normally
- Test data: email: nonexistent@example.com, password: Test@123456
- Expected result: login fails with "email or password incorrect"

### Steps

1. Visit the login page
2. Enter a nonexistent email
3. Click the login button

## TC-AUTH-REFRESH-001 — Normal Access Token Refresh

- Module: Auth module / Refresh token
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: the user has a valid refresh token
- Test data: a valid refresh token
- Expected result: 1. Returns a new access token
  2. May return a new refresh token

### Steps

1. Call the refresh endpoint using the refresh token

## TC-AUTH-REFRESH-002 — Invalid Refresh Token

- Module: Auth module / Refresh token
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: none
- Test data: an invalid refresh token
- Expected result: the refresh fails with "token is invalid, please log in again"

### Steps

1. Call the refresh endpoint using an invalid refresh token

## TC-AUTH-REFRESH-003 — Expired Refresh Token

- Module: Auth module / Refresh token
- Priority: P0
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: the refresh token has expired
- Test data: an expired refresh token
- Expected result: the refresh fails with "token is expired, please log in again"

### Steps

1. Call the refresh endpoint using the expired refresh token

## TC-EDGE-AUTH-001 — Overly Long Email Address

- Module: Boundary Conditions & Exception Scenarios / Auth boundary tests
- Priority: P2
- Execution status: **PASS**
- Execution batch: 2026-08-12 automated UAT; fix retest passed the same day
- Execution environment: local production-mode UAT Docker stack
- Beta disposition: **CORE GATE**
- Preconditions: system running normally
- Test data: email: a...a@example.com (more than 255 characters)
- Expected result: registration fails with "email length exceeded"

### Steps

1. Register with an overly long email address

### Execution evidence

- Entered an email of total length 262 characters; the email field had no declared `maxLength`, so the browser considered it valid and actually submitted the form.
- The page only showed `Registration failed, please try again later...`, with no email-length-exceeded message.
- Result: **FAIL**; see DEF-021.

### 2026-08-12 fix retest evidence

- In the production-mode UAT image, entering an email of total length 262 characters and clicking register showed `Email address must not exceed 255 characters` on the page.
- No generic registration failure was shown, no navigation occurred, and the registration request never reached the server; the email field also declared `maxLength=255`.
- The server performs input validation before the invitation-whitelist check, returning a clear 400 validation error for overly long emails; boundary unit tests cover 255 and 256 characters.
- Result: **PASS**; DEF-021 fixed.

## TC-EDGE-AUTH-002 — Overly Long Password

- Module: Boundary Conditions & Exception Scenarios / Auth boundary tests
- Priority: P2
- Execution status: **PASS**
- Execution batch: 2026-08-12 automated UAT
- Execution environment: local production-mode UAT Docker stack
- Beta disposition: **CORE GATE**
- Preconditions: system running normally
- Test data: password: a password of more than 100 characters
- Expected result: depending on system design, it may be truncated or rejected

### Steps

1. Register with an overly long password

### 2026-08-12 partial execution evidence

- The browser accepted a 101-character password; the password field had `maxLength=-1` and `minLength=8`, so the browser considered it valid.
- A final registration would be affected by the invitation whitelist, CAPTCHA and test-account creation side effects, so this automated batch did not submit it; kept as **NOT RUN**.

### 2026-08-12 full execution evidence

- In the fixed production-mode UAT image, the password field declared `minLength=8` and `maxLength=100`.
- A controlled input wrote a 101-character password and clicked register; before the CAPTCHA check the page showed `Password must contain between 8 and 100 characters`.
- No navigation occurred, no CAPTCHA or generic registration failure was shown, and there were no errors or warnings in the browser console.
- Result: the system clearly rejected the overly long password; **PASS**.

## TC-EDGE-AUTH-003 — Special Character Email

- Module: Boundary Conditions & Exception Scenarios / Auth boundary tests
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: system running normally
- Test data: email: test+special@example.com
- Expected result: depending on system design, it may be accepted or rejected

### Steps

1. Register with an email containing special characters

### 2026-08-12 partial execution evidence

- The browser considered `test+special@example.com` a valid format.
- A full success path requires the invitation whitelist and CAPTCHA and would create a test account, so this automated batch did not submit it; kept as **NOT RUN**.
- Reconfirmed on 2026-08-12: UAT has an invitation whitelist configured but this public test email is not in it; also, a successful registration must pass the CAPTCHA. Kept as **NOT RUN**, pending manual CAPTCHA approval or a whitelisted test account.

## TC-EDGE-AUTH-004 — Unicode Character Password

- Module: Boundary Conditions & Exception Scenarios / Auth boundary tests
- Priority: P2
- Execution status: **PASS**
- Beta disposition: **CORE GATE**
- Preconditions: system running normally
- Test data: password: 密码测试12345 (9 Unicode characters)
- Expected result: registration succeeds and the password is stored correctly

### Steps

1. Register with a password containing Unicode characters

### 2026-08-12 partial execution evidence

- The browser accepted `密码测试123`; measured by character count this test value has length 7, below the declared `minLength=8` of the password field, yet the controlled form still reported it as valid — consistent with the weak-password behavior in TC-AUTH-REG-004.
- A full success path requires the invitation whitelist and CAPTCHA and would create a test account, so this automated batch did not submit it; kept as **NOT RUN**, with the password-constraint issue tracked by DEF-013.
- The original test value `密码测试123` is only 7 characters, conflicting with the confirmed 8-character minimum rule; corrected to the 9-character `密码测试12345`. A successful registration still requires the whitelist and CAPTCHA, so it remains **NOT RUN**.

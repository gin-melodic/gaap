# Online demo info

## Demo user

The backend provides passwordless browser login and maintains realistic transaction history for the
configured online demo user. It identifies the user by `ONLINE_DEMO_USER_EMAIL`; the corresponding
`ONLINE_DEMO_USER_PASSWORD` remains in the API process and is never sent to the browser.

Configure both values to enable the online demo. Leaving both empty disables it; configuring only
one is an error. The user must already exist, its stored password must match, and 2FA must be off:

```dotenv
ONLINE_DEMO_USER_EMAIL=demo@example.com
ONLINE_DEMO_USER_PASSWORD=replace-with-the-real-password
```

The API captures the user's profile, accounts, transactions, and generator completion records once,
before it starts the scheduler. This immutable baseline is restored in one database transaction at
midnight in `DEMO_DATA_TIMEZONE`. New, edited, and soft-deleted demo data is therefore discarded,
while other users are untouched. Password and 2FA changes are rejected for the demo user so the
public login button remains available. Multiple API instances serialize on the baseline row and a
completed business date is not reset twice.

### Automatic transaction generation

The generator is disabled by default. Enable it only in the environment that owns the public demo
user:

```dotenv
DEMO_DATA_GENERATOR_ENABLED=true
ONLINE_DEMO_USER_EMAIL=demo@example.com
ONLINE_DEMO_USER_PASSWORD=replace-with-the-real-password
DEMO_DATA_START_DATE=2026-04-02
DEMO_DATA_TIMEZONE=America/Los_Angeles
```

`ONLINE_DEMO_USER_EMAIL` should use the environment's real demo address; the value above is only an
example. The start date and timezone are optional and default to the values shown.

When enabled, the API restores the daily baseline first and then runs catch-up in the background. It
processes each unfinished business date from the start date through yesterday, then wakes at
midnight in the configured timezone. The initial rollout has a minimum backfill endpoint of
`2026-08-23`, including
when Los Angeles has not yet crossed into August 24. Failed catch-up attempts retry after 15 minutes.
Each day is committed as one database transaction and is protected by a unique completion record, so
restarts and multiple API instances do not duplicate data. A successfully processed day may contain
zero transactions.

Generated transactions use only the restored demo user's active, non-group accounts in the base currency.
Amounts use cents, and asset or liability balances are never allowed to become negative. Disable the
job by removing the variable or setting `DEMO_DATA_GENERATOR_ENABLED=false`; existing generated data
is retained.

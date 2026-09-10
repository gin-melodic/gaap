# GAAP Cloud — Version Baseline Management

This document defines the standardized version-baseline rules for GAAP Cloud
(`gaap-api` backend + `gaap-web` frontend). It is the single source of truth for
how versions are named, how baselines are assigned, and how release notes stay
synchronized between the in-app UI and the repository.

## 1. Version scheme

- All versions follow **Semantic Versioning** (`MAJOR.MINOR.PATCH`) with a
  `v` prefix: `v0.0.2-beta`.
- While the product is in **Beta**, every user-visible baseline carries the
  `-beta` pre-release suffix and increments the **patch** number:
  `v0.0.1-beta` → `v0.0.2-beta` → `v0.0.3-beta` → …
- General availability (if/when it happens) starts at `v1.0.0` and drops the
  suffix; pre-release suffixes then follow SemVer (`-rc.1`, `-alpha`, …).
- `gaap-web/package.json` and `gaap-api/go.mod` do **not** define the product
  version; they are build artifacts. The product baseline is defined exactly
  where stated in §4.

## 2. Baselines

A **baseline** is an immutable, releasable snapshot of the product plus its
release notes. Rules:

1. **Immutability** — once a baseline is released, its entries are never
   edited in place. Corrections and follow-ups go into the next baseline.
2. **One baseline, one set of notes** — every baseline has exactly one entry
   in `CHANGELOG.md` and exactly one entry in the in-app changelog data.
3. **Next baseline reservation** — work in progress always targets the next
   unused baseline number. Do not reuse or reorder reserved numbers.
4. **Release authority** — the release owner (product maintainer) declares
   which content ships under which baseline. The exact entry text is provided
   by the release owner before each release; drafts in the repo are
   provisional until that confirmation.

## 3. Current baseline register

| Baseline    | Status                    | Description                                              |
|-------------|---------------------------|----------------------------------------------------------|
| `v0.0.1-beta` | **Released** 2026-08-14  | Invite-only Beta — core ledger (live on `gaap.cc`)       |
| `v0.0.2-beta` | **In flight** (unreleased) | Multi-currency extension: per-currency accounts, exchange-rate management, base-currency valuation |

Next available baseline after `v0.0.2-beta` ships: **`v0.0.3-beta`**.

## 4. Single source of truth for the version

| Artifact                                              | Role                                                        |
|-------------------------------------------------------|-------------------------------------------------------------|
| `CHANGELOG.md` (repo root, **English only**)          | Canonical record of all released baselines and their notes  |
| `gaap-web/src/lib/version.ts` → `APP_VERSION`         | Current in-flight baseline used by the app UI (settings row + changelog footer) |
| `gaap-web/src/lib/changelog.ts` → `CHANGELOG_RELEASES` | In-app changelog data (versions, dates, status, note keys) |
| `gaap-web/src/locales/{en,zh-CN,zh-TW,ja}/changelog.json` | Localized note text for the in-app changelog module      |

## 5. Release flow (per baseline)

Performed in order; the release owner steps 1–3 drive the content:

1. **Freeze scope** — the release owner confirms the baseline number (e.g.
   `v0.0.2-beta`) and provides the final changelog content.
2. **Author notes** —
   - finalize the four locale files `gaap-web/src/locales/*/changelog.json`;
   - in `gaap-web/src/lib/changelog.ts`: set the release's `released: true`,
     set `date` to the release day (ISO), verify its `items` cover the notes;
   - add the baseline section to root `CHANGELOG.md` (English only), with the
     same entries (1:1 parity with the in-app content).
3. **Bump the app version** — set `APP_VERSION` in
   `gaap-web/src/lib/version.ts` to the released baseline.
4. **Commit & tag** —
   - commit `gaap-api` / `gaap-web` submodule changes and sync the pointers in
     the root repo (root commit includes `CHANGELOG.md`);
   - tag the root repository with the baseline name, e.g. `v0.0.2-beta`.
5. **Reserve the next number** — update the §3 register: the released line
   becomes `Released <date>`, and the next unused number is reserved for the
   in-flight work.

## 6. In-app changelog invariants

- The in-app list is rendered **newest first**; `CHANGELOG_RELEASES` must stay
  sorted descending by version.
- Every released baseline appears in **both** `CHANGELOG.md` and the in-app
  data, with 1:1 entry parity (en locale ↔ CHANGELOG.md).
- The `en` locale is the reference for parity checks; `zh-CN`, `zh-TW`, `ja`
  must contain the same keys.
- Note text is always sourced from `src/locales/` — no hardcoded UI strings
  in the changelog component (project i18n rule).

## 7. What does NOT count as a baseline

Internal refactors, test-only changes, CI/infra tweaks, and dependency bumps
that produce no user-visible change are folded into the next baseline's notes
(or omitted) rather than minting a new version.

# DEF-025: Dashboard chart `width(-1)` / `height(-1)` console warnings

**Status**: RESOLVED (2026-09-03) — implemented and verified.

## Context

DEF-025 was tracked as P2: the dashboard balance-trend chart container briefly emitted
`The width(-1) and height(-1) of chart should be greater than 0...` console warnings on page
initialization and reloads, although charts rendered normally afterwards (charts render normally).

Root cause: recharts' `ResponsiveContainer` (`SizeDetectorContainer`) initializes its internal size
state to `{width: -1, height: -1}` and renders children during the client-side pass that happens
before the first `ResizeObserver` measurement, so every mount fires one warning.

## Decisions

- Measure the chart container ourselves (layout effect + `ResizeObserver`) and only mount the chart
  once real pixel dimensions are known, passing them as explicit numeric `width`/`height`. Explicit
  numbers take recharts' static sizing path (no internal size-detector pass, no `-1` state), which
  also removes a one-frame layout ambiguity.
- No recharts upgrade and no change to chart data/margins — the fix is isolated to container mounting.

## Implementation

- `gaap-web/src/components/features/BalanceTrendChart.tsx`: new local `useMeasuredSize(ref)` hook;
  the existing `h-[300px] w-full relative` wrapper now carries `ref={chartContainerRef}` and renders
  `<ResponsiveContainer width={measuredSize.width} height={measuredSize.height}>` only when both
  dimensions are > 0 (otherwise nothing — the fixed-height wrapper keeps layout stable during fetch).

## Verification

- New regression test `gaap-web/src/components/features/BalanceTrendChart.test.tsx`: mounts the chart
  in jsdom with a stubbed `ResizeObserver`, waits for the recharts SVG surface, and asserts zero
  console warnings containing `should be greater than 0` / `width(-1)`.
- Negative control: running the same test against the pre-fix component (via `git stash`) fails on the
  captured `width(-1)` warning; with the fix it passes.
- Full web suite green: 94 passed, 8 skipped (vitest), `tsc --noEmit` clean, ESLint clean.

## Local UAT verification (2026-09-04)

- Playwright mock on local UAT after the DEF-027 rebuild:
  `GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF025-DASH-CHART","status":"PASS","detail":"surfaces=2, sizeWarnings=[]"}`.

## Local UAT verification (2026-09-04)

- Playwright mock on local UAT after the DEF-027 rebuild:
  `GAAP_UAT_BROWSER_GATE={"id":"BROWSER-DEF025-DASH-CHART","status":"PASS","detail":"surfaces=2, sizeWarnings=[]"}`.

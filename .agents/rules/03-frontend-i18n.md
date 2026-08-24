---
trigger: model_decision
description: Modifying or writing frontend pages, UI components, or content involving copywriting or internationalization (i18n) in gaap-web triggers mandatory execution.
---

**Frontend Architecture & State:**
- Framework: Next.js 16 (App Router). NEVER use float for money, use `Decimal.js`.
- State: Use TanStack Query for server state. Local React state ONLY for UI-local concerns.
- Tokens: Auto-refresh via `src/lib/services/secureAuthService.ts`. Store in `localStorage`.
- UI: Radix UI + Tailwind. Lucide React for icons. Sonner for toasts.

**Frontend i18n Rules (CRITICAL):**
- When modifying or adding front-end code (UI components, strings, toasts, errors), you MUST use i18n for internationalization.
- Target Languages: You MUST update the i18n JSON configurations for ALL four languages in `src/locales/`:
  - `en` (English)
  - `ja` (Japanese)
  - `zh-CN` (Simplified Chinese)
  - `zh-TW` (Traditional Chinese)
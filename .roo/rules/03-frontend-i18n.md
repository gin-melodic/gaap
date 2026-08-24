---
description: 编写或修改 gaap-web 前端页面、UI 组件以及涉及到文案或多语言(i18n)时强制触发。
alwaysApply: false
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

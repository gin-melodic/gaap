---
alwaysApply: false
globs: docker-compose*.yml,manifest/sql/**/*.sql,.env*
---

**Infrastructure & Services:**
- Postgres: ACID compliance. Migrations in `manifest/sql/` auto-run on startup. NEVER skip migrations for schema changes (always create SQL files).
- Redis: Session caching, distributed locks (prevent race conditions).
- Debugging Go: Set `ENABLE_DELVE=true` in `.env`, attach debugger on port 40000.

**开发环境编译规范：**
- 禁止在开发时执行 `npm build`、`go build` 等生产编译命令
- 这些命令会生成编译产物（如 `.next` 目录），导致开发环境 HMR 失效
- 前端开发：使用 Docker dev 容器内的 `npm run dev`，通过 HMR 热更新
- 后端开发：使用 Docker dev 容器内的 `air` 热更新，或设置 `ENABLE_DELVE=true` 使用 Delve 调试
- 如需清理编译产物：删除 `.next` 目录或执行 `docker restart <container>`

**AI Core Behavior (Vibe Coding Rules):**
1. 绝对禁止占位符：严禁使用 `// 此处省略` 等占位符，必须输出完整的文件代码。
2. 避免盲目修改：跨文件重构前必须先读取完整目录结构 (`ls/tree`)。
3. 严格遵循类型安全：利用 Go 的严格类型作为财务逻辑防线。
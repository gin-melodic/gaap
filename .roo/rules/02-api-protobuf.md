---
description: 涉及 Protobuf 协议更新、执行代码生成脚本或前后端 API Hook 联调时触发。
globs: *.proto
alwaysApply: false
---
**Protobuf-First API Workflow:**
All APIs are defined in Protobuf (`manifest/protobuf/`). You MUST follow this:

**Backend API Update Flow:**
1. Define message in `manifest/protobuf/{domain}/v1/{domain}.proto`.
2. Run Generator: `go run utility/genctrl/main.go manifest/protobuf api`
   (Parses .proto, infers HTTP routes, outputs wrapper structs with GoFrame `g.Meta` tags).
3. Run GoFrame controller generator: `gf gen ctrl`.
4. Implement business logic in `internal/logic/`. Use `gf gen dao` if DB changed. Update DAOs in `internal/dao/`.

**Frontend API Update Flow:**
1. Run `npm run proto` to regenerate types in `src/lib/proto/`.
2. Create/Update hook in `src/lib/hooks/use{Domain}.ts` (wraps service calls with TanStack Query).

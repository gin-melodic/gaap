# 健康检查 UAT

> 本文件只保留本次 Beta 范围内的用例；非 Beta 用例统一存放于 `deferred.md`。PASS 仅代表原 UAT 已通过，NOT RUN 表示尚未执行。

## TC-HEALTH-001 — 系统健康检查

- 模块：健康检查模块 / 系统健康检查
- 优先级：P0
- 执行状态：**PASS**
- 执行批次：2026-08-12 自动化 UAT；同日修复复测通过
- 执行环境：本地 production-mode UAT Docker 栈
- Beta 处置：**CORE GATE**
- 前置条件：系统正常运行
- 测试数据：无
- 预期结果：1. live 返回状态码200
2. ready 在 PostgreSQL、Redis、RabbitMQ 和迁移均正常时返回状态码200
3. 任一核心依赖不可用时 ready 返回状态码503

### 步骤

1. 调用健康检查接口

### 执行证据

- 全部依赖 healthy 时：`live` 返回 HTTP 200 / `{"status":"alive"}`，`ready` 返回 HTTP 200 / `{"status":"ready"}`。
- 分别停止 PostgreSQL、Redis、RabbitMQ 时：`ready` 均返回 HTTP 503 / `{"status":"unavailable"}`；停止 Redis、RabbitMQ 时 `live` 仍返回 HTTP 200。
- PostgreSQL 与 Redis 恢复 healthy 后，`ready` 自动恢复 HTTP 200。
- RabbitMQ 恢复 healthy 后，`ready` 持续返回 HTTP 503，只有重启 API 后才恢复 HTTP 200；**FAIL**，见 DEF-020。

### 2026-08-12 修复复测证据

- 停止 RabbitMQ 后，API 保持运行且 `ready` 返回 HTTP 503 / `{"status":"unavailable"}`。
- 恢复 RabbitMQ 后未重启 API；连接监督器通过退避重试自动重连，`ready` 恢复 HTTP 200 / `{"status":"ready"}`。
- `gaap.tasks` 与 `gaap.dashboard` 均重新注册 1 个需要 ACK 的消费者。
- 结果：**PASS**；DEF-020 已修复。

## TC-HEALTH-002 — 数据库连接检查

- 模块：健康检查模块 / 系统健康检查
- 优先级：P0
- 执行状态：**PASS**
- 执行批次：2026-08-12 自动化 UAT
- 执行环境：本地 production-mode UAT Docker 栈
- Beta 处置：**CORE GATE**
- 前置条件：数据库正常运行
- 测试数据：无
- 预期结果：返回数据库连接状态为健康

### 步骤

1. 调用健康检查接口
2. 检查数据库连接状态

### 执行证据

- PostgreSQL healthy 时 `ready` 为 HTTP 200；停止 PostgreSQL 后降为 HTTP 503；恢复 PostgreSQL 后自动恢复 HTTP 200；**PASS**。

## TC-HEALTH-003 — Redis连接检查

- 模块：健康检查模块 / 系统健康检查
- 优先级：P0
- 执行状态：**PASS**
- 执行批次：2026-08-12 自动化 UAT
- 执行环境：本地 production-mode UAT Docker 栈
- Beta 处置：**CORE GATE**
- 前置条件：Redis正常运行
- 测试数据：无
- 预期结果：返回Redis连接状态为健康

### 步骤

1. 调用健康检查接口
2. 检查Redis连接状态

### 执行证据

- Redis healthy 时 `ready` 为 HTTP 200；停止 Redis 后降为 HTTP 503 且 `live` 保持 HTTP 200；恢复 Redis 后 `ready` 自动恢复 HTTP 200；**PASS**。

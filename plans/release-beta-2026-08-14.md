# GAAP 邀请制 Beta 上线计划

版本：2026-08-13 修订版  
目标发布日期：2026-08-14  
目标域名：`gaap.cc`  
当前验收环境：`https://gaap.local`

本文档是本次 Beta 的唯一主上线计划。UAT 状态以 `plans/uat/` 为准，生产操作以
`docs/production-runbook.md` 为准，组件取舍依据
`docs/beta-component-dependency-audit.md`。

## 1. 当前基线与上线范围

- 原 UAT 因问题过多而中止，仅 8 个用例有历史 PASS：
  `TC-AUTH-REG-001` 至 `005`、`TC-AUTH-LOGIN-001` 至 `003`。
- 其余 112 个原用例未执行，不视为失败或通过；逐条复核 Beta 协议、UI 和用户等级后
  划分为 74 个 CORE GATE 和 38 个 DEFERRED。
- 自动化测试当前基线：后端 121 个、前端 58 个通过，但不能替代人工 UAT。
- 生产使用全新 PostgreSQL 数据库，不导入 UAT 数据。
- Beta 采用服务端邮箱白名单、低并发邀请制和单用户基准币种。

首版开放：

- 白名单注册；
- 登录、刷新、退出及多设备独立 session；
- 资产、负债、收入、支出账户；
- 收入、支出、转账及交易更新、删除；
- 基础 Dashboard 与 30 天余额趋势；
- live、ready、HTTPS、备份恢复。

首版延期：

- 2FA 设置与启用；
- 密码修改；
- 有交易账户的迁移删除；
- Pro 用户、账户组和子账户；
- 任务中心、数据导入导出；
- WebSocket 用户入口；
- 汇率、多币种账户和换算估值。

## 2. 生产组件基线

生产与 UAT 均部署：Caddy、Next.js Web、GoFrame API、PostgreSQL、Redis、RabbitMQ。

RabbitMQ 是 Dashboard 快照刷新链路的核心依赖，不能再因任务中心延期而删除。
RabbitMQ、PostgreSQL 和 Redis 只加入 Docker 内部数据网络，不向公网或宿主机开放
业务端口。

API 启动必须成功连接 PostgreSQL、Redis 和 RabbitMQ 并完成迁移；ready 同时检查：

- PostgreSQL 可查询；
- Redis/ALE 可用；
- RabbitMQ 连接仍存活；
- 所有 `manifest/sql` 迁移已记录。

任一核心依赖不可用时 API 不应接收流量。RabbitMQ 运行中重启后，若 ready 返回
503，本版运行手册要求联动重启 API，以重新连接并注册消费者；完整 AMQP 自动重连
列为上线前优先整改或明确接受的运行风险。

## 3. 核心整改状态

### UAT 与缺陷基线

- **已完成**：Excel 工作簿拆分为 `plans/uat/` Markdown，旧 Excel 弃用。
- **已完成**：8 个历史 PASS 与其余 NOT RUN/DEFERRED 状态按真实结果记录。
- **已完成**：原 Bug、TODO 和新增 UAT 问题合并到 `plans/uat/defects.md`。
- **已完成**：2026-08-12 人工 UAT 批次通过；批次范围按
  `plans/uat/manual-runs.md` 记录。
- **进行中**：将人工批次结果映射到逐用例证据，并完成尚未登记的 CORE GATE。
- **门禁**：核心用例不得保持 NOT RUN；DEFERRED 不得写成 PASS。

### ALE + Protobuf

- **已完成**：业务请求收敛到 `secureRequest + protobuf + ALE`。
- **已完成**：统一 protobuf 错误结构和 session 丢失 401 标记。
- **已完成**：JWT 使用 `sid`，Redis session 按用户与设备隔离，refresh 保持 sid 并轮换。
- **已完成**：Redis session key 丢失时返回可识别的 401，不向用户暴露
  `OperationError`。
- **待门禁**：篡改、重放、过期 timestamp、无效 sid、敏感日志扫描和两设备并发。

### 账务安全与 Dashboard

- **已完成**：交易账户归属、账户类型、币种、金额、同账户和排序字段校验。
- **已完成**：创建、更新、删除交易使用数据库事务，提交后再失效缓存和刷新 Dashboard。
- **已完成**：账户按固定 UUID 顺序加锁，更新检查受影响行数。
- **已完成**：后端金额使用 `shopspring/decimal`，前端金额使用 Decimal.js。
- **已完成**：交易和账户变更同时失效 Redis 与 PostgreSQL Dashboard 旧快照；前端同时
  失效 Dashboard Query。
- **已完成**：API 启动从账户和交易真值重建 Dashboard，不再直接恢复可能过期的持久化
  快照。
- **已完成**：RabbitMQ Dashboard worker 在 UAT/生产模式启动，API/ready 对 RabbitMQ
  fail closed。
- **已完成**：有交易账户由后端拒绝删除，前端不再显示迁移删除界面。
- **待门禁**：历史日期交易创建、更新、删除后的趋势；并发写入；回滚；会计等式。
- **已实现 / 待 UAT**：账户组与子账户成功路径已延期；服务端已拒绝 Free/Beta 用户
  直接提交 `is_group` 或 `parent_id`，并覆盖未指定、Free、Pro 等级边界测试。

### 启动余额与对账策略

旧启动余额重算使用字符串查询整数交易枚举，且只覆盖部分交易方向和账户类型。简单修到
“可执行”可能在启动时批量改错余额。

本版策略：

- **已完成**：从生产/UAT启动链路移除自动余额改写；
- 账户余额只由创建、更新、删除交易的数据库事务更新并持久化；
- 启动只重建派生 Dashboard，不静默修账；
- **上线门禁**：增加或执行只读对账，覆盖资产、负债、收入、支出、权益、期初余额和
  转账；发现差异时阻止发布并保留现场。

### 生产运行能力

- **已完成**：版本化迁移、生产镜像、非 root/read-only 容器、Caddy、PostgreSQL、
  Redis、RabbitMQ Compose。
- **已完成**：`/v1/health/live` 和 `/v1/health/ready`。
- **已完成**：本地加密备份与独立恢复数据库演练。
- **已完成**：`gaap.local` HTTPS UAT 环境。
- **待完成**：VPS Secret、`gaap.cc` DNS/HTTPS、真实 Turnstile 域名、安全响应头、
  每日备份定时任务和生产恢复演练。
- **待完成**：生产基础设施镜像固定到已验证精确版本或 digest。

## 4. 测试与发布门禁

自动化门禁：

- Go 1.24：`go test ./...`；
- Node 22：Vitest、ESLint、TypeScript；
- protobuf/GoFrame 生成代码无漂移；
- API、Web 两个生产镜像构建；
- UAT 与生产 Compose 配置校验。

人工与集成门禁：

- 8 个历史 PASS 全部重新通过；
- 74 个 CORE GATE 全部执行并通过；
- 白名单注册、登录、refresh、logout；
- 创建资产、负债、收入、支出账户；
- 创建收入、支出、转账；
- 更新、删除交易并核对双方余额；
- 历史日期交易在 Dashboard 正确日期产生变化；
- RabbitMQ 两个队列消费者存在，Dashboard 消息无积压；
- Redis、RabbitMQ、API 重启后的 session、ready 和 Dashboard 行为符合预期；
- 只读账务对账无差异；
- HTTPS、Turnstile、备份恢复完成。

以下任一失败立即停止发布：账务不一致、越权、ALE 泄密或无法解密、核心 P0/P1、
RabbitMQ/Dashboard 丢刷新、迁移失败、备份无法恢复。

## 5. 修订时间表

### 8 月 12 日周三

- **已完成**：ALE session 丢失 401、即时创建支出账户、Dashboard 历史交易缺失修复。
- **已完成**：RabbitMQ 加入 UAT/生产栈，API/ready fail closed。
- **已完成**：组件依赖审计、启动余额自动改写下线、迁移删除 UI 收敛。
- **已完成**：人工 UAT 批次通过（用户于 2026-08-13 确认）；逐用例范围和证据仍按
  `plans/uat/` 状态继续收口。

### 8 月 13 日周四

- **已完成开发 / 待集成 UAT**：修复 DEF-019，增加账户组/子账户服务端等级门禁及
  自动化边界测试；
- 完成 8 个历史回归和本版全部 P0/P1 CORE GATE；
- 完成只读账务对账及并发、回滚、历史日期 Dashboard 场景；
- 验证 RabbitMQ 重启恢复方案；
- 部署 VPS 预生产，验证生产 Compose、迁移、HTTPS、Turnstile、安全头；
- 完成生产备份恢复演练。

### 8 月 14 日周五上午

- 只修阻断缺陷，不增加功能；
- 重新运行完整自动化、核心 UAT、账务对账和生产 smoke；
- 生成 API/Web 不可变镜像标签并记录 digest；
- 生成发布前数据库备份。

### 8 月 14 日周五下午

- 部署 `gaap.cc`；
- 执行公网注册、登录、账户、交易、Dashboard、refresh、logout、HTTPS 和容器重启
  smoke；
- smoke 全部通过后开放邮箱白名单；
- 至少观察 2 小时：5xx、ALE、refresh 循环、RabbitMQ 连接与积压、数据库锁等待和
  账务对账。

应用故障回滚上一不可变镜像；数据库故障先停止写流量并保留现场，再依据发布前加密
备份恢复。禁止在已有新写入的数据库上盲目执行向下迁移。

## 6. 当前 Go / No-Go

截至 2026-08-13：**NO-GO（尚未满足公网发布门禁）**。

已具备继续 UAT 的本地运行基线，但以下事项仍阻止公网发布：

- 2026-08-12 人工 UAT 批次已通过，但尚未完成全部逐用例证据映射；
- 核心 P0/P1 UAT 尚未全部登记为 PASS；
- DEF-019 已实现自动化门禁，仍需执行绕过 UI 的集成 UAT；
- 只读账务对账尚未完成；
- VPS、真实 DNS/HTTPS/Turnstile 和生产备份恢复尚未验收。

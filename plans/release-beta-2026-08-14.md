# GAAP 邀请制 Beta 上线计划

版本：2026-08-13 修订版  
目标发布日期：2026-08-14  
目标域名：`gaap.cc`  
当前验收环境：`https://gaap.local`

本文档是本次 Beta 的唯一主上线计划。UAT 状态以 `plans/uat/` 为准，生产操作以
`docs/production-runbook.md` 为准，组件取舍依据
`docs/beta-component-dependency-audit.md`。

## 1. 当前基线与上线范围

- 2026-08-13 批次 `UAT-20260813-BETA-RC-01` 已重跑 8 个历史 CORE REGRESSION 并
  完成 74 个 CORE GATE：82/82 PASS，0 FAIL，0 NOT RUN。
- 原 120 个用例中另有 38 个 DEFERRED，保持 NOT RUN，不计入 Beta 功能范围。
- 自动化测试当前基线：后端 152 个、前端 74 个常规测试通过；真实浏览器和协议结果
  单独登记为 UAT，不以单元测试替代。
- 生产使用全新 PostgreSQL 数据库，不导入 UAT 数据。
- Beta 采用服务端邮箱白名单、低并发邀请制和单用户基准币种。

首版开放：

- 白名单注册；
- 登录、刷新、退出及多设备独立 session；
- 资产、负债、收入、支出账户；
- 收入、支出、转账及交易更新、删除；
- 基础 Dashboard 与 30 天余额趋势；
- live、ready 和 HTTPS。

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

任一核心依赖不可用时 API 不应接收流量。RabbitMQ 运行中重启时 ready 返回 503；
连接监督器通过退避自动重连，2026-08-13 UAT 在 17 秒内恢复 ready 200，
`gaap.dashboard` 与 `gaap.tasks` 各自动恢复 1 个消费者，无需重启 API。

## 3. 核心整改状态

### UAT 与缺陷基线

- **已完成**：Excel 工作簿拆分为 `plans/uat/` Markdown，旧 Excel 弃用。
- **已完成**：8 个历史 PASS 与其余 NOT RUN/DEFERRED 状态按真实结果记录。
- **已完成**：原 Bug、TODO 和新增 UAT 问题合并到 `plans/uat/defects.md`。
- **已完成**：2026-08-12 人工 UAT 批次通过；批次范围按
  `plans/uat/manual-runs.md` 记录。
- **已完成**：全量 UAT 结果映射到 82 个 Beta 用例，证据见
  `plans/uat/runs/2026-08-13-beta-rc-01.md`。
- **门禁**：核心用例不得保持 NOT RUN；DEFERRED 不得写成 PASS。

### ALE + Protobuf

- **已完成**：业务请求收敛到 `secureRequest + protobuf + ALE`。
- **已完成**：统一 protobuf 错误结构和 session 丢失 401 标记。
- **已完成**：JWT 使用 `sid`，Redis session 按用户与设备隔离，refresh 保持 sid 并轮换。
- **已完成**：Redis session key 丢失时返回可识别的 401，不向用户暴露
  `OperationError`。
- **门禁通过**：篡改、重放、过期 timestamp、无效 sid、敏感日志扫描和多设备独立
  refresh/logout 全部通过。

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
- **已完成自动化门禁**：历史日期交易创建、更新、删除后的趋势；固定 UUID 顺序行锁；
  第二账户更新失败时的事务回滚；跨全部账户类型的流水重算及 1 nano 差异边界。
- **UAT 通过**：最终只读对账检查 142 个账户、62 笔有效交易，无余额差异或完整性
  异常；真实浏览器与协议确认历史交易创建、移动日期、删除后的 30 天趋势正确收敛。
- **UAT 通过**：账户组与子账户成功路径已延期；Free/Beta 用户直接提交 `is_group`
  或 `parent_id` 均被拒绝，且账户与期初余额交易无脏写入。

### 启动余额与对账策略

旧启动余额重算使用字符串查询整数交易枚举，且只覆盖部分交易方向和账户类型。简单修到
“可执行”可能在启动时批量改错余额。

本版策略：

- **已完成**：从生产/UAT启动链路移除自动余额改写；
- 账户余额只由创建、更新、删除交易的数据库事务更新并持久化；
- 启动只重建派生 Dashboard，不静默修账；
- **已完成**：增加强制 PostgreSQL `READ ONLY` 的对账命令，覆盖资产、负债、收入、
  支出、权益、期初余额和转账；发现差异时以非零状态退出，不写回数据。

### 生产运行能力

- **已完成**：版本化迁移、生产镜像、非 root/read-only 容器、Caddy、PostgreSQL、
  Redis、RabbitMQ Compose。
- **已完成**：`/v1/health/live` 和 `/v1/health/ready`。
- **已完成**：本地加密备份与独立恢复数据库演练。
- **已完成**：`gaap.local` HTTPS UAT 环境。
- **已完成**：生产 Secret 生成并以 `0600` 权限部署；API/Web 使用已验证的
  `linux/amd64` 精确 digest，生产基础设施启动 5 个迁移。
- **已完成**：VPS 上 API/Web/PostgreSQL/Redis/RabbitMQ 健康；两个 RabbitMQ 队列各
  1 个消费者且无积压；空生产库只读对账通过。
- **部分完成**：RabbitMQ 重启期间 ready 返回 503 并在 14 秒恢复，Redis 和 API
  重启后分别在 0 秒和 1 秒恢复；重启后只读对账再次通过。
- **已解决**：Cloudflare DNS、橙云、HTTPS 和安全头已恢复；多余的历史 Origin Rule
  曾将 `gaap.cc` 错误转发至 VPS `8081` 并导致 525，删除后真实 Turnstile 和
  公网业务 smoke 均已通过。
- **WAIVED / ACCEPTED RISK**：发布负责人于 2026-08-14 12:15 CST 确认，本轮
  不需要生产备份、独立恢复演练和每日备份任务；三项从 Beta 发布门禁移除，
  不写成 PASS。已接受数据库故障时无可验证生产恢复点、不能承诺恢复最新数据的风险。

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
- HTTPS 与 Turnstile 完成。

以下任一失败立即停止发布：账务不一致、越权、ALE 泄密或无法解密、核心 P0/P1、
RabbitMQ/Dashboard 丢刷新、迁移失败。

## 5. 修订时间表

### 8 月 12 日周三

- **已完成**：ALE session 丢失 401、即时创建支出账户、Dashboard 历史交易缺失修复。
- **已完成**：RabbitMQ 加入 UAT/生产栈，API/ready fail closed。
- **已完成**：组件依赖审计、启动余额自动改写下线、迁移删除 UI 收敛。
- **已完成**：人工 UAT 批次通过（用户于 2026-08-13 确认）；逐用例范围和证据仍按
  `plans/uat/` 状态继续收口。

### 8 月 13 日周四

- **已完成**：修复 DEF-019 并完成绕过 UI 的真实协议复测；
- **已完成**：8 个历史回归和全部 74 个 CORE GATE；
- **已完成**：只读账务对账、并发、故障回滚、历史日期 Dashboard 和 RabbitMQ 自动
  恢复门禁；
- **已完成**：三仓库发布分支与草稿 PR、API/Web 候选镜像和不可变 digest；生产候选
  已部署到 `/opt/gaap` 的隔离端口，迁移、健康、消费者、依赖重启和空库对账通过。
- **已完成**：Cloudflare DNS、Caddy HTTPS 与安全头恢复；真实 Turnstile 签发 token，
  `windane@gmail.com` 白名单生产注册通过。执行跨过 2026-08-14 00:00，剩余生产 smoke
  转入 8 月 14 日白天，不回填为 8 月 13 日完成。
- **当时决策**：生产备份、独立恢复演练和每日备份任务本轮不执行，截至当时
  保持 NO-GO；该决策已于 2026-08-14 12:15 CST 由发布负责人更新为正式豁免。

### 8 月 14 日周五上午

- **已完成**：开启橙云后绕过 Cloudflare 直连 `144.34.237.205`，请求直达源站、
  TLS 证书、HTTP→HTTPS、Web/Caddy 路由、API ready 和安全响应头全部通过；
- **已完成**：Cloudflare 历史 Origin Rule 曾将 `gaap.cc` 错误转发至 VPS `8081`
  并触发 525；该规则已删除，公网登录页恢复后，生产重新注册、登录、四类账户、
  收入/支出/转账、交易更新与删除、Dashboard、refresh 和 logout smoke 全部通过；
- **已完成**：生产只读账务对账检查 6 个账户、4 笔交易，`passed=true`、
  `differences=[]`、`issues=[]`；RabbitMQ 两队列各 1 个消费者、无积压；最终应用日志
  无 ERROR/WARN/PANIC/FATAL 或 5xx；浏览器控制台无 error，新发现的图表尺寸和 Dialog
  可访问性 warning 以及交易时间控件/日期协议不一致已登记为非阻断 DEF-025/026/027；
- **已完成（逾期收尾）**：发布负责人于 2026-08-14 12:15 CST 确认最终 GO；
  截至 12:22 CST，生产证据已更新，文档已提交并推送，PR 检查通过，根、API、Web
  三个工作区已确认干净；
- **已确认**：Caddyfile 权限已由发布负责人恢复，Cloudflare 橙云已开启且公网访问正常；
- **WAIVED / ACCEPTED RISK**：发布前数据库备份、独立恢复演练和每日备份任务
  不在本轮执行，且不再构成发布阻断。

### 8 月 14 日周五下午

- 部署 `gaap.cc`；
- 执行公网注册、登录、账户、交易、Dashboard、refresh、logout、HTTPS 和容器重启
  smoke；
- smoke 全部通过后开放邮箱白名单；
- 至少观察 2 小时：5xx、ALE、refresh 循环、RabbitMQ 连接与积压、数据库锁等待和
  账务对账。

应用故障回滚上一不可变镜像；数据库故障先停止写流量并保留现场。由于本轮已豁免
生产备份/恢复门禁，不承诺存在可用恢复点；禁止在已有新写入的数据库上盲目执行向下迁移。

## 6. 当前 Go / No-Go

发布负责人于 2026-08-14 12:15 CST 确认，并于 12:22 CST 完成文档推送与 PR 检查：
**最终结论为 GO（邀请制 Beta）**。

本地 RC、VPS 容器、DNS/HTTPS、真实 Turnstile、源站直连、生产业务 smoke、RabbitMQ 复核、
生产只读对账和最终应用日志扫描均通过。没有未关闭的 Beta P0/P1；DEF-025/026/027
为已记录的非阻断 P2。

发布负责人明确将生产备份、独立恢复演练和每日备份从本轮 Beta 门禁移除，
记为 **WAIVED / ACCEPTED RISK** 而非 PASS。此豁免不改变技术结果，但意味着数据库故障时
无可验证生产恢复点，可能无法恢复最新业务数据。发布后继续执行至少 2 小时观察。

## 7. 候选产物记录

- UAT 批次：`UAT-20260813-BETA-RC-01`（82/82 PASS）。
- API 提交：`2a163356eca1b5edb6b66a87a467aadeddf37dcb`。
- Web 提交：`6862ca2825b0b2da86760ada4a84507f46c47eaf`。
- API 候选标签：
  `ghcr.io/gin-melodic/gaap-api:beta-2026-08-14-2a163356eca1b5edb6b66a87a467aadeddf37dcb`。
- Web 候选标签：
  `ghcr.io/gin-melodic/gaap-web:beta-2026-08-14-6862ca2825b0b2da86760ada4a84507f46c47eaf`。
- API digest：`sha256:7e7546fef26de2da228c13b9db4658dddc1cf439d6b93e1773dcfc3ac75e5be8`。
- Web digest：`sha256:4c3ef686d0085c854695f2fb1ba74a7b06010e641a888c4f362ed32c7191e3fc`。
- 根候选基础设施提交：`826b5cf46587554526710cc83f79b3045ac2f9b2`。
- 草稿 PR：根仓库 [#2](https://github.com/gin-melodic/gaap/pull/2)、API
  [#5](https://github.com/gin-melodic/gaap-api/pull/5)、Web
  [#8](https://github.com/gin-melodic/gaap-web/pull/8)。
- API/Web/根 CI：PASS。
- GitHub Actions secrets 已登记 `BETA_ALE_BOOTSTRAP_KEY` 与
  `BETA_TURNSTILE_SITE_KEY`；未在证据中记录 Secret 值。
- VPS Compose 使用上述 `image@sha256:...`，未部署 `latest`；执行证据见
  [`UAT-20260813-VPS-RC-01`](uat/runs/2026-08-13-vps-rc-01.md)。

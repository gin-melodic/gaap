# 自动化 Smoke 记录

本文件记录工程验证，不改变任何 UAT 用例状态。只有人工按用例执行并留存证据后，才可将 `NOT RUN` 改为 `PASS`。

## 2026-08-11 — 本地生产模式完整链路

- 环境：最终 production Docker 镜像；全新 PostgreSQL/Redis 临时卷；生产配置校验开启；Cloudflare Turnstile 官方测试 Key。
- 协议：真实 ALE 加密 + HMAC + nonce + Protobuf，请求通过临时本地 Caddy 到 API。
- 结果：**PASS（工程 smoke，非 UAT）**
- 覆盖：
  - 白名单注册、登录、refresh、logout；
  - 创建资产、负债、收入、支出账户；
  - 创建收入、支出、转账；
  - 将支出从 USD 50 更新为 USD 60；
  - 删除 USD 25 转账并确认流水不再返回；
  - 核对资产余额精确为 USD 1140.000000000；
  - Dashboard 余额趋势请求；
  - API `ready`；生产日志错误与敏感模式扫描。
- 清理：临时容器、网络、PostgreSQL/Redis 数据卷、环境文件和协议客户端已删除；无 smoke 数据保留。
- 未覆盖：跨用户越权、故障注入回滚、并发锁/死锁、真实 Turnstile 域名、DNS/HTTPS、VPS 重启、浏览器 CAPTCHA 交互与全部 CORE GATE。

## 2026-08-12 — 自动化 UAT 启动基线

- 环境：`docker-compose.uat.yml` 本地 UAT 栈；PostgreSQL、Redis、RabbitMQ、API、Web 与 Caddy 均为 healthy。
- 入口：正式 UAT HTTPS 入口使用 Caddy 内部 CA；自动化浏览器不绕过证书警告，另启仅绑定 `127.0.0.1:8080` 的临时 HTTP 代理连接同一 UAT 容器。
- 结果：**PASS（启动 smoke，非完整 UAT）**
- 覆盖：
  - `/v1/health/live` 返回 HTTP 200 与 `{"status":"alive"}`；
  - `/v1/health/ready` 返回 HTTP 200 与 `{"status":"ready"}`；
  - 登录页和注册页可完成客户端渲染，控制台无错误或警告；
  - 登录空字段由浏览器必填约束拦截；
  - 注册无效邮箱由浏览器邮箱格式约束拦截；
  - 密码与确认密码具有最小长度 8 的客户端约束。
- 持续执行：已创建当前任务的 UAT heartbeat 自动化，每 30 分钟继续执行安全的 CORE REGRESSION / CORE GATE 并更新证据。
- 未覆盖：本记录不改变任何 UAT 用例状态；登录/注册提交、CAPTCHA、刷新令牌、账户、交易、Dashboard、安全与并发门禁仍待后续批次执行。

## 2026-08-14 — 生产源站直连验证

- 时间：2026-08-14 10:57 CST。
- 目标：绕过 Cloudflare，使用 `gaap.cc` TLS SNI/Host 直连 `144.34.237.205`。
- 结果：**PASS（发布负责人确认）**。
- 已确认通过：
  - 请求确实直达源站；
  - 源站 TLS 证书；
  - HTTP 自动跳转 HTTPS；
  - Web 与 Caddy 路由；
  - API `/api/v1/health/ready`；
  - 源站安全响应头。
- 未覆盖：本条仅收口源站直连门禁；生产登录、账户、交易、Dashboard、refresh、
  logout、RabbitMQ 复核和真实数据对账仍需单独执行。

## 2026-08-14 — 生产业务 Smoke 入口故障与恢复

- 时间：2026-08-14 10:58 CST。
- 结果：**RESOLVED；业务 smoke 继续执行**。
- 公网 `https://gaap.cc/login` 经浏览器和 `curl` 均返回 HTTP 525；Cloudflare 页面报告
  `SSL handshake failed`、`Host Error`，Ray ID 为 `a2acb279cbb8d29b` 和
  `a2acb2cb2c4b85d7-NRT`。
- 同一时刻使用 `gaap.cc` SNI/Host 直连 `144.34.237.205` 的 `/login` 返回
  HTTP 200 与 HTML，证明 Web/Caddy 源站本身可用。
- 根因：Cloudflare 中存在多余的历史 Origin Rule，该规则将 `gaap.cc` 错误转发到
  VPS `8081` 端口。
- 处置：删除历史 Origin Rule，保持 Cloudflare 橙云开启；重新打开公网
  `https://gaap.cc/login` 已恢复为 GAAP Cloud 登录页。
- 故障期间未执行任何登录或业务写入。

## 2026-08-14 — 生产测试用户重置

- 目标邮箱：`windane@gmail.com`（发布负责人确认为生产测试用户并授权删除）。
- 删除前用户 ID：`517a7171-45e8-4f83-90b2-46c6910c2ae9`；账户、交易、任务、
  Dashboard 快照和 OAuth 关联记录计数均为 0。
- 操作：在事务中按用户 ID 与邮箱双重条件删除，结果 `DELETE 1` 并成功提交。
- 删除后验证：该邮箱用户数为 0，包含旧用户 ID 的 Redis session/cache 键数为 0，
  API `/v1/health/ready` 仍返回 `{"status":"ready"}`。
- 下一步：使用同一白名单邮箱重新注册，然后继续生产业务 smoke。

## 2026-08-14 — 生产业务 Smoke 与最终对账

- 时间：2026-08-14 11:52–12:02 CST。
- 用户：`windane@gmail.com`，重新注册后用户 ID 为
  `e5bc892b-8498-4ecb-9d89-3d86b036194b`。
- 结果：**PASS**。
- 认证：白名单重新注册成功并自动进入 Dashboard；页面 reload 后 session 和数据保持；
  logout 后返回 `/login`，该 session 对应的 Redis ALE key 数为 0。
- 账户：创建 Asset `SMOKE-20260814-Cash` USD 1,000、Liability
  `SMOKE-20260814-Card` USD 200、Income `SMOKE-20260814-Income` 和 Expense
  `SMOKE-20260814-Expense`。
- 交易：创建 Income→Cash USD 300、Cash→Expense USD 50 和 Cash→Card USD 25；
  将支出更新为 USD 60，再删除 USD 25 转账，交易列表不再返回已删除转账。
- 最终账户余额：Cash `1240.000000000`、Card `200.000000000`、Income
  `-300.000000000`、Expense `60.000000000`；Dashboard 显示资产 USD 1,240、
  负债 USD 200、净资产 USD 1,040、月收入 USD 300 和月支出 USD 60。
- 强制只读对账：`passed=true`，`accountsChecked=6`，`transactionsChecked=4`，
  `differences=[]`，`issues=[]`。其中 6 个账户包括系统自动创建的 2 个期初权益账户，
  4 笔有效交易包括 2 笔期初余额、1 笔收入和 1 笔支出。
- RabbitMQ：`gaap.tasks` 与 `gaap.dashboard` 均为 1 个消费者，
  `messages_ready=0`、`messages_unacknowledged=0`。
- 服务端日志：Smoke 时间窗内 API/Web 无 ERROR/WARN/PANIC/FATAL，精确 HTTP 状态扫描无
  5xx。删除旧测试用户前的旧密码登录 401 和重复注册 403 为已解释的预期拒绝。
- 浏览器控制台：无 error；观察到 Dashboard 图表初始化容器尺寸为 `-1` 和 Dialog 缺少
  `Description/aria-describedby` 的非阻断 warning，分别登记为 DEF-025 与 DEF-026。
- 日期语义：新建表单允许输入时分秒，但 API 返回仅日期后，交易列表和编辑表单在
  上海时区统一回显 08:00；本次按日账务和 Dashboard 验收不受影响，登记为非阻断
  DEF-027。

## 2026-08-14 — 最终 GO 决策

- 时间：2026-08-14 12:15 CST 确认发布决策；12:22 CST 完成文档提交、推送和 PR 检查。
  上午任务在中午 12:00 后收尾，记为逾期完成。
- 结论：**GO（邀请制 Beta）**。
- 依据：源站与公网入口、生产业务 smoke、RabbitMQ、只读账务对账、logout session 失效和
  服务端日志门禁均通过，无未关闭 Beta P0/P1。
- 豁免：发布负责人明确确认本轮不需要生产备份、独立恢复演练和每日备份；
  三项记为 `WAIVED / ACCEPTED RISK`，不记为 PASS，不再构成本轮发布阻断。
- 已接受风险：数据库故障时无可验证生产恢复点，不承诺可恢复最新业务数据；
  应用镜像仍可回滚，数据库故障必须先停写并保留现场。
- 发布后义务：至少观察 2 小时，持续监控 5xx、ALE/refresh、RabbitMQ、数据库锁等待和账务对账。

## 2026-08-14 — 发布后两小时观察收口

- 观察窗口：2026-08-14 12:15–14:20 CST；13:20 和 14:20 执行完整检查，窗口内持续检查
  公网 ready。
- 结果：**PASS**。公网 live 和 ready 在最终检查均返回 HTTP 200，分别为
  `{"status":"alive"}` 和 `{"status":"ready"}`。
- 容器：GAAP API、Web、PostgreSQL、Redis 和 RabbitMQ 5 个生产容器均持续运行且
  `healthy`；公网入口同时证明主机 Caddy、Cloudflare 和应用路由可用。
- RabbitMQ：`gaap.tasks` 与 `gaap.dashboard` 均为 1 个消费者，
  `messages_ready=0`、`messages_unacknowledged=0`。
- PostgreSQL：锁等待为 0，运行超过 5 分钟的事务为 0。
- 日志：从 12:15 CST 起，生产 API、Web、PostgreSQL、Redis 和 RabbitMQ 日志中
  ERROR/WARN/PANIC/FATAL、HTTP 5xx、ALE/HMAC/nonce/decrypt 失败、refresh 异常和
  Redis 失败模式计数均为 0。
- 强制只读对账：`passed=true`，`accountsChecked=6`，`transactionsChecked=4`，
  `differences=[]`，`issues=[]`。对账器启动时报告容器内 `/app/.env` 不存在的既知警告，
  生产配置由 Compose 注入且对账成功，该警告未进入运行中服务日志。
- 结论：发布后两小时观察义务完成；未触发应用回滚或数据库停写条件。

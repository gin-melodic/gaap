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

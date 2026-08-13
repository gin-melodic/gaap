# Beta 缺陷清单

此文件合并原工作簿的 Bug 和 TODO，并补入源码审计确认的阻断问题。

| ID | 严重级别 | 模块 | 描述 | 状态 | 验证用例 | 修复提交 |
|---|---|---|---|---|---|---|
| DEF-001 | P0 | 账户/币种 | 新账户默认 USD，但设置页基准币种显示 CNY | IMPLEMENTED / UAT REQUIRED | TC-ACCT-CREATE-001 | release 分支待提交 |
| DEF-002 | P0 | 账户汇总 | 父账户金额未按基准币种显示且符号错误 | DEFERRED / PRO FEATURE | 延期账户组回归 | release 分支待提交 |
| DEF-003 | P1 | 设置/汇率 | 汇率更新产生两次 toast | DEFERRED / UI HIDDEN | 延后功能 | release 分支待提交 |
| DEF-004 | P0 | 账户创建 | 新账户及父子账户未统一使用用户基准币种 | IMPLEMENTED / BETA UAT + GROUP DEFERRED | TC-ACCT-CREATE-001；TC-ACCT-CREATE-004 延期 | release 分支待提交 |
| DEF-005 | P1 | 账户创建 | 新增账户产生多次 toast | IMPLEMENTED / TESTED | TC-ACCT-CREATE-001 | release 分支待提交 |
| DEF-006 | P0 | ALE | 日志输出密钥和解密后的请求/响应载荷 | IMPLEMENTED / SCANNED | 安全日志扫描 | release 分支待提交 |
| DEF-007 | P0 | 交易权限 | 交易可引用其他用户账户并修改其余额 | IMPLEMENTED / INTEGRATION REQUIRED | TC-EDGE-SEC-003 | release 分支待提交 |
| DEF-008 | P0 | 交易查询 | sort_by 未白名单，存在 SQL 注入风险 | IMPLEMENTED / TESTED | TC-EDGE-SEC-001 | release 分支待提交 |
| DEF-009 | P0 | 交易事务 | 创建交易失败路径可能未回滚，提交错误被忽略 | IMPLEMENTED / FAILURE-INJECTION TESTED / INTEGRATION REQUIRED | TC-EDGE-DATA-001 | 316bc88 + 工作区待提交 |
| DEF-010 | P0 | 协议 | 前端 JSON 与 ALE+PB 请求栈并存 | IMPLEMENTED / SMOKE TESTED | 协议集成测试 | release 分支待提交 |
| DEF-011 | P0 | 金额 | 前端 Dashboard/账户汇总使用 number 与硬编码汇率 | IMPLEMENTED / TESTED | 金额边界测试 | release 分支待提交 |
| DEF-012 | P0 | 部署 | 生产 Compose、迁移版本和可用性探针不完整 | PARTIAL / VPS SMOKE REQUIRED | 部署 smoke test | release 分支待提交 |
| DEF-013 | P0 | 认证 | 登录 Turnstile 未在服务端校验，浏览器预哈希导致弱密码可绕过 UI 校验；6 位密码曾可提交且只显示通用失败 | IMPLEMENTED / FAILED CASE UAT PASS / FULL AUTH UAT REQUIRED | TC-AUTH-REG-003 至 005、TC-AUTH-LOGIN-001 至 003 | 工作区待提交 |
| DEF-014 | P0 | 交易/即时开户 | 即时创建支出账户后未使用返回账户类型，资产→支出被误提交为转账并遗留孤儿账户 | IMPLEMENTED / UAT REQUIRED | TC-TXN-CREATE-002、即时创建支出账户扩展场景 | release 分支待提交 |
| DEF-015 | P0 | ALE/交易删除 | Redis 中 session key 缺失时未形成可识别的 401，前端直接暴露 `OperationError`；删除请求实际未进入控制器 | IMPLEMENTED / AUTOMATED + DOCKER VERIFIED / UAT REQUIRED | 删除交易、Redis 重启后失效 session、session key 同步恢复扩展场景 | release 分支待提交 |
| DEF-016 | P0 | Dashboard/RabbitMQ | 生产模式跳过 RabbitMQ 初始化，交易后仅清 Redis 快照又从 PostgreSQL 恢复旧快照，历史日期交易不进入趋势图 | IMPLEMENTED / DOCKER + AUTOMATED VERIFIED / UAT REQUIRED | 历史日期交易创建、更新、删除后的趋势图；RabbitMQ/ready | 316bc88 + 工作区待提交 |
| DEF-017 | P0 | 启动/余额 | 启动余额重算用字符串查询整数枚举且会跳过失败账户；规则不完整，不适合作为生产自动修复器 | MITIGATED / UAT RECONCILIATION PASS | 容器重启余额不变；只读账户余额与交易流水对账 | 316bc88 + 工作区待提交 |
| DEF-018 | P1 | 账户删除 | 后端已禁止迁移删除，但前端仍显示迁移目标选择并暗示任务可执行 | IMPLEMENTED / UAT REQUIRED | 有交易账户删除、无交易账户删除 | release 分支待提交 |
| DEF-019 | P0 | 账户权限 | 账户组 UI 仅对 Pro 开放，但创建账户服务尚未校验用户等级；Free/Beta 用户可绕过 UI 提交 `is_group` 或 `parent_id` | IMPLEMENTED / AUTOMATED / UAT REQUIRED | TC-EDGE-SEC-003；TC-ACCT-CREATE-003/004 保持延期 | 工作区待提交 |
| DEF-020 | P0 | RabbitMQ/可用性 | RabbitMQ 短暂中断后，容器恢复 healthy 但 API 客户端不会自动重连，`ready` 持续 503，必须重启 API 才恢复 | RESOLVED / UAT PASS | TC-HEALTH-001；RabbitMQ 恢复测试 | 工作区待提交 |
| DEF-021 | P1 | 认证/邮箱边界 | 注册邮箱框没有最大长度限制；262 字符邮箱可提交，页面只显示通用失败而非长度超限提示 | RESOLVED / UAT PASS | TC-EDGE-AUTH-001 | 工作区待提交 |

`IMPLEMENTED` 只表示代码整改已完成，不等同于 UAT `PASS`。`SCANNED` 表示已完成源码日志模式扫描，仍需在预生产采集实际日志复核。2026-08-11 已完成全新 PostgreSQL/Redis 容器迁移、live/ready、生产镜像，以及加密备份恢复到独立数据库的预演；公网 DNS、HTTPS 与真实 Turnstile 仍需在 VPS 验证。2026-08-12 已对 DEF-015 执行缺失 `sid` 的 `gaap.local` HTTPS 协议验证：返回 HTTP 401、protobuf 响应及 `X-ALE-Session-Expired: 1`。同日完成 RabbitMQ 故障注入修复复测：中断时 ready 返回 503，恢复后 API 无需重启即自动重连，`gaap.dashboard` 与 `gaap.tasks` 消费者均恢复，DEF-020 关闭。2026-08-13 已为 DEF-019 增加服务端等级门禁：未指定和 Free 等级提交 `is_group` 或 `parent_id` 均被拒绝，Pro 等级保留成功路径；账户创建与更新共用该校验。同日只读 UAT 对账检查 9 个账户、5 笔交易且无差异；并发锁、故障回滚和历史日期 Dashboard 创建/更新/删除场景通过自动化测试。DEF-016、018、019 仍需浏览器或协议集成人工 UAT。

# Beta 缺陷清单

此文件合并原工作簿的 Bug 和 TODO，并补入源码审计确认的阻断问题。

| ID | 严重级别 | 模块 | 描述 | 状态 | 验证用例 | 修复提交 |
|---|---|---|---|---|---|---|
| DEF-001 | P0 | 账户/币种 | 新账户默认 USD，但设置页基准币种显示 CNY | RESOLVED / UAT PASS | TC-ACCT-CREATE-001 | release 分支待提交 |
| DEF-002 | P0 | 账户汇总 | 父账户金额未按基准币种显示且符号错误 | DEFERRED / PRO FEATURE | 延期账户组回归 | release 分支待提交 |
| DEF-003 | P1 | 设置/汇率 | 汇率更新产生两次 toast | DEFERRED / UI HIDDEN | 延后功能 | release 分支待提交 |
| DEF-004 | P0 | 账户创建 | 新账户及父子账户未统一使用用户基准币种 | RESOLVED / BETA UAT PASS + GROUP DEFERRED | TC-ACCT-CREATE-001；TC-ACCT-CREATE-004 延期 | release 分支待提交 |
| DEF-005 | P1 | 账户创建 | 新增账户产生多次 toast | IMPLEMENTED / TESTED | TC-ACCT-CREATE-001 | release 分支待提交 |
| DEF-006 | P0 | ALE | 日志输出密钥和解密后的请求/响应载荷 | RESOLVED / UAT LOG SCAN PASS | 安全日志扫描 | release 分支待提交 |
| DEF-007 | P0 | 交易权限 | 交易可引用其他用户账户并修改其余额 | RESOLVED / UAT PASS | TC-EDGE-SEC-003 | release 分支待提交 |
| DEF-008 | P0 | 交易查询 | sort_by 未白名单，存在 SQL 注入风险 | IMPLEMENTED / TESTED | TC-EDGE-SEC-001 | release 分支待提交 |
| DEF-009 | P0 | 交易事务 | 创建交易失败路径可能未回滚，提交错误被忽略 | RESOLVED / FAILURE-INJECTION + UAT PASS | TC-EDGE-DATA-001 | 316bc88 + 工作区待提交 |
| DEF-010 | P0 | 协议 | 前端 JSON 与 ALE+PB 请求栈并存 | IMPLEMENTED / SMOKE TESTED | 协议集成测试 | release 分支待提交 |
| DEF-011 | P0 | 金额 | 前端 Dashboard/账户汇总使用 number 与硬编码汇率 | IMPLEMENTED / TESTED | 金额边界测试 | release 分支待提交 |
| DEF-012 | P0 | 部署 | 生产 Compose、迁移版本和可用性探针不完整 | PARTIAL / VPS CONTAINERS PASS / PUBLIC DNS BLOCKED | 部署 smoke test | `826b5cf` |
| DEF-013 | P0 | 认证 | 登录 Turnstile 未在服务端校验，浏览器预哈希导致弱密码可绕过 UI 校验；6 位密码曾可提交且只显示通用失败 | RESOLVED / FULL AUTH UAT PASS | TC-AUTH-REG-003 至 005、TC-AUTH-LOGIN-001 至 003 | 工作区待提交 |
| DEF-014 | P0 | 交易/即时开户 | 即时创建支出账户后未使用返回账户类型，资产→支出被误提交为转账并遗留孤儿账户 | RESOLVED / UAT PASS | TC-TXN-CREATE-002、即时创建支出账户扩展场景 | release 分支待提交 |
| DEF-015 | P0 | ALE/交易删除 | Redis 中 session key 缺失时未形成可识别的 401，前端直接暴露 `OperationError`；删除请求实际未进入控制器 | RESOLVED / UAT PASS | 删除交易、Redis 重启后 session、session key 同步恢复扩展场景 | release 分支待提交 |
| DEF-016 | P0 | Dashboard/RabbitMQ | 生产模式跳过 RabbitMQ 初始化，交易后仅清 Redis 快照又从 PostgreSQL 恢复旧快照，历史日期交易不进入趋势图 | RESOLVED / UAT PASS | 历史日期交易创建、更新、删除后的趋势图；RabbitMQ/ready | 316bc88 + 工作区待提交 |
| DEF-017 | P0 | 启动/余额 | 启动余额重算用字符串查询整数枚举且会跳过失败账户；规则不完整，不适合作为生产自动修复器 | MITIGATED / UAT RECONCILIATION PASS | 容器重启余额不变；只读账户余额与交易流水对账 | 316bc88 + 工作区待提交 |
| DEF-018 | P1 | 账户删除 | 后端已禁止迁移删除，但前端仍显示迁移目标选择并暗示任务可执行 | RESOLVED / UAT PASS | 有交易账户删除、无交易账户删除 | release 分支待提交 |
| DEF-019 | P0 | 账户权限 | 账户组 UI 仅对 Pro 开放，但创建账户服务尚未校验用户等级；Free/Beta 用户可绕过 UI 提交 `is_group` 或 `parent_id` | RESOLVED / UAT PASS | TC-EDGE-SEC-003；TC-ACCT-CREATE-003/004 保持延期 | 工作区待提交 |
| DEF-020 | P0 | RabbitMQ/可用性 | RabbitMQ 短暂中断后，容器恢复 healthy 但 API 客户端不会自动重连，`ready` 持续 503，必须重启 API 才恢复 | RESOLVED / UAT PASS | TC-HEALTH-001；RabbitMQ 恢复测试 | 工作区待提交 |
| DEF-021 | P1 | 认证/邮箱边界 | 注册邮箱框没有最大长度限制；262 字符邮箱可提交，页面只显示通用失败而非长度超限提示 | RESOLVED / UAT PASS | TC-EDGE-AUTH-001 | 工作区待提交 |
| DEF-022 | P0 | 金额/数据库 | API 允许的金额上界超过 `NUMERIC(20,9)`，大额账户和交易在 PostgreSQL 溢出 | RESOLVED / UAT PASS | TC-EDGE-ACCT-001、TC-TXN-CREATE-010 | `2a163356` |
| DEF-023 | P1 | 输入边界 | 超长账户名称和交易备注落到数据库错误并触发不必要的 session 重同步 | RESOLVED / UAT PASS | TC-EDGE-ACCT-002、TC-EDGE-TXN-003 | `2a163356` |
| DEF-024 | P1 | Dashboard/币种 | profile 加载前 Dashboard 以 USD 格式化 CNY 余额并抛出币种不匹配 | RESOLVED / BROWSER UAT PASS | TC-DASH-SUMMARY-001、TC-DASH-TREND-001 | `4937d1db` |

`IMPLEMENTED` 只表示代码整改已完成，不等同于 UAT `PASS`。2026-08-13 批次
`UAT-20260813-BETA-RC-01` 已完成协议、浏览器、ALE 攻击、依赖恢复和只读对账，Beta
范围缺陷均完成复测；最终对账检查 142 个账户、62 笔交易且无差异或完整性异常。
VPS 容器、迁移、消费者、重启恢复和空库对账已通过。Cloudflare token 无权访问
`gaap.cc` zone，且 `www` 为 NXDOMAIN，故公网 DNS、HTTPS、真实 Turnstile 和业务 smoke
仍被阻断；生产备份恢复按发布负责人决定保持 DEFERRED / NO-GO。

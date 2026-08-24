# gaap.local 本地 UAT

## 访问与注册

- 地址：`https://gaap.local`
- 白名单邮箱：`uat@gaap.local`
- 密码与昵称由测试人员自行设置。
- Turnstile 使用 Cloudflare 官方测试 Key，不产生真实验证码或公网生产数据。
- UAT 状态只在 `plans/uat/` 更新；不要恢复或继续编辑旧 Excel。

首次访问时，如果浏览器不信任 Caddy 本地 CA，可手动打开
`config/caddy/gaap-local-root.crt`，将其加入“登录”钥匙串，并在“信任”中设置为
“始终信任”。这是本地 CA，不应复制到其他设备或生产服务器。

## 常用命令

启动或更新当前源码：

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml up -d --build
```

查看状态与日志：

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml ps
docker compose --env-file .env.uat -f docker-compose.uat.yml logs -f gaap-api gaap-web rabbitmq caddy
```

停止服务但保留 UAT 数据：

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml stop
```

重新启动：

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml start
```

仅当明确需要重置全部 UAT 数据时，才执行下面命令；它会删除 PostgreSQL、Redis
、RabbitMQ 和 Caddy 数据卷，无法恢复：

```sh
docker compose --env-file .env.uat -f docker-compose.uat.yml down -v
```

## UAT 执行规则

- 先重新执行 8 个 `CORE REGRESSION`。
- 再执行本版 74 个 `CORE GATE`。
- 38 个延期用例集中在 `plans/uat/deferred.md`，保持 `NOT RUN / DEFERRED`。
- 发现缺陷时更新 `plans/uat/defects.md`，写明复现步骤、严重级别、修复提交和验证用例。
- 不得因为自动化测试或 smoke 通过而直接把人工 UAT 用例改为 `PASS`。

2026-08-13 批次 `UAT-20260813-BETA-RC-01` 已使用真实浏览器和真实 protobuf + ALE
HTTPS 链路完成 82/82 Beta 用例；执行证据见
`plans/uat/runs/2026-08-13-beta-rc-01.md`。38 个 DEFERRED 用例仍保持 NOT RUN。

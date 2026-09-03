# GAAP 邀请制 Beta 生产运行手册

主上线计划：`plans/release-beta-2026-08-14.md`。

## 发布前提

- Ubuntu VPS 已安装 Docker Engine 与 Compose Plugin。
- `gaap.cc` 和 `www.gaap.cc` 已解析到 VPS；80/443 已放行。
- Cloudflare Turnstile 已添加 `gaap.cc`，Site Key 与 Secret 成对。
- 本次发布使用全新 PostgreSQL 数据库，不导入 UAT 数据。
- RabbitMQ 是 Dashboard 刷新链路的核心依赖，不因任务中心延期而移出生产栈。
- 认证已改为 ALE 内传输原始密码并由服务端 bcrypt；旧的浏览器 SHA-256 密码记录不兼容，预生产测试账号必须重建。
- `plans/uat/` 中 8 个历史 PASS 已回归，本版全部 CORE GATE 已执行并通过。

## 生产配置

在服务器 `/opt/gaap` 下复制示例文件，并限制权限：

```sh
cp .env.production.example .env.production
chmod 600 .env.production
install -d -m 700 /opt/gaap/secrets /opt/gaap/backups
openssl rand -base64 48 > /opt/gaap/secrets/backup.key
chmod 600 /opt/gaap/secrets/backup.key
```

必须替换所有示例值。`ALE_BOOTSTRAP_KEY` 与构建 Web 镜像时传入的
`NEXT_PUBLIC_ALE_BOOTSTRAP_KEY` 必须完全相同；它是浏览器公开配置，不能替代 JWT、
数据库、Redis 或 Turnstile Secret。

## 构建不可变镜像

使用发布号或 Git SHA，不使用 `latest`：

```sh
docker build --target production \
  -t ghcr.io/your-org/gaap-api:2026-08-14.1 ./gaap-api

docker build --target production \
  --build-arg NEXT_PUBLIC_ALE_BOOTSTRAP_KEY="$NEXT_PUBLIC_ALE_BOOTSTRAP_KEY" \
  --build-arg NEXT_PUBLIC_TURNSTILE_SITE_KEY="$NEXT_PUBLIC_TURNSTILE_SITE_KEY" \
  -t ghcr.io/your-org/gaap-web:2026-08-14.1 ./gaap-web
```

推送镜像后，将相同不可变标签写入 `.env.production` 的 `GAAP_API_IMAGE` 和
`GAAP_WEB_IMAGE`。

## 部署与验证

```sh
docker compose --env-file .env.production -f docker-compose.production.yml config
docker compose --env-file .env.production -f docker-compose.production.yml pull
docker compose --env-file .env.production -f docker-compose.production.yml up -d
docker compose --env-file .env.production -f docker-compose.production.yml ps
curl --fail https://gaap.cc/api/v1/health/live
curl --fail https://gaap.cc/api/v1/health/ready
```

随后按 `plans/uat/` 执行公网白名单注册、登录、账户、收入/支出/转账、交易更新与
删除、余额核对、刷新轮换、退出、容器重启恢复和 HTTPS 安全头 smoke test。

在开放白名单前执行只读账务对账；`passed` 必须为 `true`，`differences` 和 `issues`
必须为空：

```sh
docker compose --env-file .env.production -f docker-compose.production.yml \
  run --rm --no-deps gaap-api ./reconcile
```

命令会在读取前启用 PostgreSQL `REPEATABLE READ, READ ONLY`。退出码 `2` 表示发现
账务差异或完整性异常，此时禁止发布并保留数据库现场，不要手工改余额。

## 备份与恢复

每日运行：

```sh
GAAP_PROJECT_DIR=/opt/gaap /opt/gaap/scripts/production/backup-postgres.sh
```

恢复演练必须写入独立空数据库：

```sh
GAAP_PROJECT_DIR=/opt/gaap GAAP_RESTORE_DB=gaap_restore \
  /opt/gaap/scripts/production/restore-postgres.sh /absolute/path/to/backup.sql.gz.enc
```

备份脚本使用 AES-256-CBC + PBKDF2 加密并保留至少 7 天。恢复真实生产库前必须先
停止写流量并保留当前数据库备份。

## 回滚

- 应用故障：将 `.env.production` 的镜像标签改回上一发布并重新 `up -d`。
- 账务或迁移故障：停止写流量，保留故障现场，使用发布前加密备份恢复；不要在有
  新写入的数据库上直接向下迁移。
- 发布后至少观察 2 小时：5xx、ALE/HMAC 失败、refresh 循环、Redis 错误、数据库锁
  等待、RabbitMQ 连接/积压，以及账户余额与交易流水对账。
- RabbitMQ 重启时 API ready 应暂时返回 503；连接监督器会自动重连并重新注册消费者。
  恢复后确认 ready 返回 200，且 `gaap.dashboard` 和 `gaap.tasks` 各有一个消费者；超过
  退避恢复窗口仍未恢复时才按故障处理并保留日志，不把重启 API 当作正常恢复步骤。

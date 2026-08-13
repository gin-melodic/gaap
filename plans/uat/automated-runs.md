# 自动化与对账执行记录

## 2026-08-13 — 账务与 Dashboard 发布门禁

- 环境：`gaap.local` UAT Compose，PostgreSQL 18。
- 只读对账命令：
  `docker compose --env-file .env.uat -f docker-compose.uat.yml run --rm --no-deps gaap-api ./reconcile`
- 只读保证：命令在读取前启用 PostgreSQL `REPEATABLE READ, READ ONLY`，以同一快照
  读取账户和交易；只报告差异，不执行余额修复。
- 对账结果：PASS；9 个有效账户、5 笔有效交易，0 个余额差异，0 个完整性异常。
- 自动化结果：`go test ./...` PASS。
- 覆盖场景：资产、负债、收入、支出、权益、期初余额、转账、1 nano 差异、跨用户、
  跨币种、固定 UUID 顺序 `SELECT FOR UPDATE`、第二账户更新失败时事务回滚，以及历史
  日期交易创建、更新、删除后的 30 天 Dashboard 日终余额。
- 浏览器只读检查：现有 2026-08-02、08-05、08-06 历史交易正常显示，Dashboard 30 天
  趋势正常加载；本批次未新增、修改或删除 UAT 数据。

---
description: 修改 gaap-api 后端 logic 层代码时触发。
globs: internal/logic/**/*.go
alwaysApply: false
---

**Logic 层开发规范：**

1. **ORM 规范**
   - 禁止硬编码数据库字段名，必须使用 DAO 生成的 Columns 结构体
   - 示例：`Where("id", userId)` → `Where(dao.Users.Columns().Id, userId)`
   - 示例：`g.Map{"field": value}` → `g.Map{dao.Table.Columns().Field: value}`

2. **事务处理**
   - 涉及多次数据库查询和修改的操作必须使用事务，保证原子性
   - 使用 `g.DB().Transaction()` 包裹整个操作，参考 `internal/logic/balance/balance.go` 写法：
     ```go
     return g.DB().Transaction(ctx, func(ctx context.Context, dbTx gdb.TX) error {
         // 在事务内使用 dbTx 执行查询和更新
     })
     ```

3. **Service 层生成**
   - 在 logic 层实现业务逻辑后，使用 `gf gen service` 自动生成 service 接口
   - 禁止手动编辑 `internal/service/*.go`，必须由工具自动生成

4. **Controller 层**
   - Controller 只负责调用 service 层方法，不包含业务逻辑
   - 返回 API 定义的 response 类型

5. **Auth 模块特殊规范**
   - 密码必须使用 bcrypt 哈希存储
   - 验证密码使用 `bcrypt.CompareHashAndPassword`

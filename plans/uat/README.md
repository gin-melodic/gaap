# GAAP Beta UAT

主上线计划：[GAAP 邀请制 Beta 上线计划](../release-beta-2026-08-14.md)。

Excel 工作簿已弃用。本目录是唯一 UAT 状态来源。

## 当前基线

- 2026-08-12 人工 UAT 批次：**PASS**（用户于 2026-08-13 确认）。由于未提供逐用例
  清单与证据，本次确认暂不批量覆盖下列逐用例统计，详见 `manual-runs.md`。

- 总用例：120
- 已通过：13
- 执行失败：0
- 未执行：107
- 本次 Beta 用例总数：82（8 个 CORE REGRESSION + 74 个 CORE GATE）
- 本次 Beta 待执行核心门禁：69
- 非 Beta 延期用例：38，已统一移至 `deferred.md`
- 资金流水测试 sheet 原为空白，未生成用例。

## 状态规则

- `PASS`：原 UAT 已实际执行并通过，必须持续回归。
- `FAIL`：已实际执行且结果不符合预期，必须修复并重新执行。
- `NOT RUN`：尚未执行，不能解释为通过或失败。
- `CORE GATE`：本次 Beta 发布前必须执行并通过。
- `DEFERRED`：功能不进入本次 Beta，保持 NOT RUN。

模块文档只保存本次 Beta 用例。所有 DEFERRED 用例只在 `deferred.md` 保存，避免执行
Beta UAT 时误选，也避免同一个用例在多个文件重复维护。

## 文件

- [认证](authentication.md)
- [账户](accounts.md)
- [交易](transactions.md)
- [Dashboard、配置与用户](dashboard-and-user.md)
- [健康检查](data-tasks-health.md)
- [安全、完整性与并发](security-integrity-concurrency.md)
- [非 Beta 延期测试用例](deferred.md)
- [缺陷清单](defects.md)
- [自动化 Smoke 记录](smoke-runs.md)
- [自动化与对账执行记录](automated-runs.md)
- [人工 UAT 批次记录](manual-runs.md)

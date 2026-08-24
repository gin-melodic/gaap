---
alwaysApply: true
---

# Runtime Environment

- OS: Windows 11
- Shell: PowerShell 7 (pwsh)
- All terminal commands must use PowerShell syntax, NOT bash/sh/zsh
- Path separator is backslash `\` or forward slash `/` (both work in pwsh)
- Use `$env:VARIABLE` for environment variables, not `$VARIABLE` or `export`
- Use `Get-Content` instead of `cat`, `Copy-Item` instead of `cp`, `Remove-Item` instead of `rm`
- Encoding: UTF-8, set via `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`

# 全局指令
- 使用中文回复
- 编码风格遵循项目已有规范，不随意引入新依赖
- 每次计划步骤不超过 5 步，优先最小可运行方案
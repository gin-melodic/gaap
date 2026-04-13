# Runtime Environment

- OS: Windows 11
- Shell: PowerShell 7 (pwsh)
- All terminal commands must use PowerShell syntax, NOT bash/sh/zsh
- Path separator is backslash `\` or forward slash `/` (both work in pwsh)
- Use `$env:VARIABLE` for environment variables, not `$VARIABLE` or `export`
- Use `Get-Content` instead of `cat`, `Copy-Item` instead of `cp`, `Remove-Item` instead of `rm`
- Encoding: UTF-8, set via `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`
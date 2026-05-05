## v1.0.0-beta3-build4

### 🐛 Bug Fixes
- Fix PS1 TUI menu clearing: replace `Write-Host (" " * WindowWidth)` with `[Console]::Write("`r{0}"...)` for reliable line clearing with wide characters (Chinese, Japanese, Korean) in Select-Language, Show-ProfileMenu, Show-SoftwareMenu
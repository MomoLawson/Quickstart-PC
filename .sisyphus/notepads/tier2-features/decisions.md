# Decisions

## 2026-04-22
- PS1 --custom: Full TUI port (arrow keys + space toggle), NOT PromptForChoice or Out-GridView
- Parallel install: Changed to install grouping/batching (apt install -y git curl wget), NOT true parallel
- Hook security: Default disabled, requires --allow-hooks opt-in
- Resume trigger: Auto-detect + --resume/--no-resume flags
- PS1 i18n: Keep inline pattern (no refactor to external files)
- Starting version: v0.69.0 (current v0.68.1)

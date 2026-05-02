## v0.83.0

### ✨ New Features
- Alternate screen buffer (like vim) — scrollback hidden during interactive TUI
- Goodbye message on exit (10 languages)
- `IN_ALT_SCREEN` flag tracking for proper screen state management
- Language selection uses alternate screen buffer
- `--dry-run` and `--check-update` show banner before update check

### 🐛 Bug Fixes
- `--version` / `--help` / `doctor` no longer trigger alternate screen (info commands)
- Error messages display on normal screen after `rmcup` (banner + INFO + error preserved)
- Ctrl+C restores cursor and shows goodbye message
- Bash 3.2 compatibility — removed `local` from trap commands
- PS1 banner encoding fix — one-liner now uses UTF-8 byte download

### 🔧 Improvements
- PS1 language strings refactored to JSON (dynamic loading, -34% size)
- CI/CD modernized — shellcheck 2.0.0, PS 7.5.1, JSON validation
- Nightly snapshot workflow added (daily pre-release builds)
- README updated for v0.83.0 with Bash vs PowerShell comparison

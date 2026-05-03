## v0.84.0

### ✨ New Features
- Bash language strings now loaded from JSON files (consistent with PS1)
- `.sh` files kept as fallback for environments without jq
- Alternate screen buffer for interactive TUI (like vim)
- Goodbye message on exit (10 languages)
- `IN_ALT_SCREEN` flag tracking for proper screen state management
- Language selection uses alternate screen buffer
- Per-software installation details in reports (elapsed, command, status)
- Nightly snapshot workflow (daily pre-release builds)
- `changelog.md` for release notes (auto-read by release.sh)

### 🐛 Bug Fixes
- JSON language loading missing `return 0` caused en-US fallback overwrite
- `--help` broken by JSON migration
- Added missing `npm_auto`/`jq_*` keys to JSON language files
- `declare -g` replaced with `eval` for Bash 3.2 compatibility
- `safe_mktemp` fallback adds `$RANDOM` for uniqueness
- Background update check properly cleaned up on exit
- Ctrl+C in language menu shows goodbye message
- Info commands (`--version`, `--help`, etc.) no longer trigger alternate screen
- `--version` outputs single line with no extra output
- Error exits restore normal screen before printing error message
- Goodbye message only on successful exit (not on errors)
- PS1 banner encoding fix for one-liner install
- PS1 hook function uses `ConvertFrom-Json` instead of jq

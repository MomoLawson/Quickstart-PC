## v0.86.0

### ✨ New Features
- Auto-detect terminal capability: `$TERM=dumb`/`unknown`/empty or `tput sgr0` failure automatically falls back to non-interactive mode

### 🐛 Bug Fixes
- Initial `tput civis` at script start now respects `NON_INTERACTIVE` flag

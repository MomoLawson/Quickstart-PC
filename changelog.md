## v1.0.0-beta2-build16

### 🐛 Bug Fixes
- Fix `is_one_liner` detection: use `basename "$0"` to handle `/bin/bash`, `-bash` etc.; add `(stdin)` match for piped execution in some environments

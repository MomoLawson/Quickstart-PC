## v1.0.0-beta3-build3

### 🐛 Bug Fixes
- Add missing `config_checksum_mismatch`, `config_verify_success`, `config_checksum_not_found`, `config_verify_failed` keys to PS1 fallback dictionary (JSON and .sh files already had them, but PS1 hardcoded fallback was missing them)
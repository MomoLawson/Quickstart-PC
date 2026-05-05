## v1.0.0-beta4-build4

### 🐛 Bug Fixes
- Fix `save_install_state` jq dependency: add python3 fallback for JSON serialization when jq unavailable
- Fix `load_install_state` jq dependency: add python3 fallback for reading state file when jq unavailable
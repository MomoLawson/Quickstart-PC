## v1.0.0-beta4-build2

### 🐛 Bug Fixes
- Fix `check_update`/`self_update`/`auto_check_update` jq dependency: add `parse_github_tag` function with jq → python3 → grep/sed fallback; call `ensure_json_parser` in `check_update` and `self_update` before GitHub API call so updates work without jq
## v1.0.0-beta2-build15

### 🐛 Bug Fixes
- Fix macOS system language detection: `head -1` was picking `(` instead of the actual language code; `cut -c1-5` truncated codes like `zh-Hans-CN`
- Add `zh-Hans`/`zh-Hans-CN`/`zh-Hant-TW` etc. to language mapping table
- Add prefix fallback when exact language code doesn't match (e.g. `zh-Hans-CN` → `zh-Hans` → `zh-CN`)

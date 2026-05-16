## v1.0.0-beta4-build5

### 🐛 Bug Fixes
- Fix PS5.1 compatibility: wrap `ConvertFrom-Json -AsHashtable` in try/catch (PS7+ feature, throws on PS5.1)
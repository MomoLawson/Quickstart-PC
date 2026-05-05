## v1.0.0-beta3-build1

### 🐛 Bug Fixes
- Fix PS1 Test-DiskSpace/Show-Doctor: fallback dictionary keys `disk_low`/`disk_warning` didn't match JSON keys `disk_space_low`/`disk_space_warning`, causing undefined key access when JSON loading failed
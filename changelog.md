## v1.0.0-beta3-build2

### 🐛 Bug Fixes
- Fix PS1 and bash batch install progress bar not updating: add `$script:current += $Keys.Count` / `install_current+=${#keys[@]}` after calling `Install-Batch`/`install_batch` in `Process-BatchGroup`/`process_batch_group`
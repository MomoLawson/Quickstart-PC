## v1.0.0-beta4-build1

### 🐛 Bug Fixes
- Fix bash `save_install_state`: use `${SELECTED_PROFILES[0]}` instead of undefined `$SELECTED_PROFILE` so state.json stores correct profile name
- Fix bash `load_install_state`: add profile comparison — clears stale state when saved profile differs from current selection
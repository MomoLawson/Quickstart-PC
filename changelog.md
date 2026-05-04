## v1.0.0-beta2-build17

### 🐛 Bug Fixes
- Fix temp file accumulation on abnormal exit: clean stale `AUTO_CHECK_FILE` at startup; make fallback path unique with `$RANDOM` to avoid PID reuse collisions

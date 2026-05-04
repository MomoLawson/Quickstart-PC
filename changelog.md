## v1.0.0-beta2-build18

### 🐛 Bug Fixes
- Fix install hang and double Ctrl+C: remove `|| true` in `install_software`/`install_batch` so exit code and SIGINT propagate correctly; show brew batch install output in real-time so user sees progress

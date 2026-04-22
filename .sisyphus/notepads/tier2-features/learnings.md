# Learnings

## 2026-04-22 Session Start
- GitHub owner: MomoLawson (NOT AirZip)
- PS1 i18n is inline switch blocks (10 blocks in one file), not external files like Bash
- Adding a LANG string to PS1 requires editing 10 places in quickstart.ps1
- install_software() uses `eval "$cmd" 2>/dev/null` — swallows all errors
- PS1 Install-Software uses `Invoke-Expression $cmd 2>&1 | Out-Null` — same problem
- PS1 --custom parameter declared but never used (dead code)
- PS1 progress bar is text-only [XXX%], no visual █░ bar
- PS1 has zero timing mechanism
- Disk check exists in --doctor for both scripts but not in install flow
- macOS bash 3.2: no declare -A, no $SECONDS reliability
- Arrow keys: must support both [A/OA formats
- Build: `bash scripts/build.sh` after every edit
- Push: needs proxy `export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897`
- Version: X.Y.Z, Y=feature, Z=bugfix, no 1.0.0 without explicit command

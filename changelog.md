## v0.85.0

### ✨ New Features
- `--help` fully translated in all 10 languages (title, usage, options)
- Bash language strings loaded from JSON files (consistent with PS1)

### 🐛 Bug Fixes
- Replace "套餐" with "预设/預設" in all Chinese translations and profile names
- `available.json` restored to only contain `languages` key
- Add missing keys to JSON language files: `continue`, `exit`, `back_to_profiles`, `custom_title`, `install_failed_list`, `lang_menu_enter`, `lang_menu_space`, `progress_installed`, `progress_to_install`, `retry_prompt`
- `--non-interactive` no longer uses alternate screen
- Remove extra empty line before goodbye message
- Translate "Usage" line in `--help` for all languages

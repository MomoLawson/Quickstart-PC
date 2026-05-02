# Quickstart-PC

> One-click computer setup - Supports Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()
[![Version](https://img.shields.io/badge/version-0.82.1-green.svg)](VERSION)

**Other Languages**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## Features

- 🚀 **One-click install** - Set up your new computer with one command
- 🎯 **12 pre-built profiles** - Curated profiles for different needs
- 🌐 **Cross-platform** - Supports Windows / macOS / Linux
- ☁️ **Remote config** - Fetch latest config from the cloud
- 📦 **Package manager** - Auto-detect and install package managers
- 🌍 **Multi-language** - 10 languages with manual selection
- 🔧 **Environment diagnostics** - `doctor` checks your system before install
- 🔄 **Auto-update** - Checks for updates on startup, Ctrl+U to update
- 🪝 **Hook scripts** - Pre/post install hooks for custom automation

## Quick Start

### macOS / Linux (Bash)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows (PowerShell)

```powershell
# Method 1: Download and run
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# Method 2: One-liner
powershell -ExecutionPolicy Bypass -Command "[System.Text.Encoding]::UTF8.GetString((New-Object System.Net.WebClient).DownloadData('https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1'))|iex"
```

## Bash vs PowerShell

| Feature | Bash (`quickstart.sh`) | PowerShell (`quickstart.ps1`) |
|---------|----------------------|-------------------------------|
| Platform | macOS, Linux | Windows, macOS, Linux |
| Language loading | `source` .sh files | JSON files via `ConvertFrom-Json` |
| Version flag | `--version` / `-v` | `-showVersion` / `-sv` |
| Doctor | `doctor` / `doctor --fix` | `doctor` / `doctor -fix` |
| Update hint | `Ctrl+U` in TUI | `Ctrl+U` in TUI |
| Config parser | `jq` (primary) / `python3` (fallback) | Native `ConvertFrom-Json` |
| TUI input | `read -rsn1` + key codes | `[Console]::ReadKey()` |

## Profiles

| Profile | Description | Included Software |
|---------|-------------|-------------------|
| ⭐ Recommended | Balanced, suitable for most users | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 AI Powered | AI CLI tools, intelligent IDEs | Cursor, Ollama, LM Studio |
| 📊 Office Suite | Documents, spreadsheets, collaboration | WPS, Obsidian, Notion |
| 💻 Developer | IDEs, version control, runtimes | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 Media | Audio/video processing tools | VLC, OBS Studio |
| 💬 Communication | Chat and messaging apps | Discord, Slack, Telegram |
| 🔒 Security | Security and privacy tools | 1Password, Bitwarden |
| 🍎 macOS Tools | macOS-specific utilities | Rectangle, Karabiner |
| 🔧 Utilities | General utility apps | Notepad++, 7-Zip |
| 🗄️ Database | Database tools | DBeaver, pgAdmin |
| ⬛ Terminal | Terminal emulators and tools | iTerm2, Windows Terminal |
| 🇨🇳 China Software | China-specific software | WeChat, QQ, WPS |

## Project Structure

```
Quickstart-PC/
├── src/                        # Source code (edit here)
│   ├── quickstart.sh           # Bash implementation
│   ├── quickstart.ps1          # PowerShell implementation
│   └── lang/                   # Language files
│       ├── en-US.sh            # Bash: shell variables (sourced)
│       ├── en-US.json          # PS1: JSON format (loaded dynamically)
│       ├── zh-CN.sh / .json    # 10 languages × 2 formats
│       └── ...
├── dist/                       # Built artifacts (don't edit)
│   ├── quickstart.sh
│   ├── quickstart.ps1
│   └── lang/
├── config/
│   ├── profiles.json           # Merged config (auto-merged by build)
│   └── software/               # Per-category JSON files
├── scripts/
│   ├── build.sh                # Merge software JSONs + inject version
│   └── release.sh              # Version bump → build → commit → tag → release
├── .github/workflows/
│   ├── quality.yml             # CI: shellcheck + PS syntax + JSON + build + smoke
│   └── release.yml             # CD: manual trigger → bump → build → release
├── VERSION                     # Single source of truth (0.82.1)
└── AGENTS.md                   # AI agent knowledge base
```

## Command Line Options

| Option | Description |
|--------|-------------|
| `--lang LANG` | Set language (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it) |
| `doctor` | Run QC Doctor environment diagnostics |
| `doctor --fix` | Auto-fix missing dependencies |
| `--dev` | Dev mode: show selections without installing |
| `--dry-run` | Preview mode: show process without installing |
| `--yes` / `-y` | Auto-confirm all prompts |
| `--verbose` | Show detailed debug info |
| `--version` / `-v` | Show version information (Bash only) |
| `--log-file FILE` | Write logs to file |
| `--export-plan FILE` | Export installation plan to file |
| `--retry-failed` | Retry previously failed packages |
| `--list-profiles` | List all available profiles |
| `--show-profile KEY` | Show profile details |
| `--skip SW` | Skip specified software (repeatable) |
| `--only SW` | Only install specified software (repeatable) |
| `--fail-fast` | Stop on first error |
| `--profile NAME` | Select profile directly (skip menu) |
| `--non-interactive` | Non-interactive mode (no TUI/prompts) |
| `--cfg-path PATH` | Use local profiles.json |
| `--cfg-url URL` | Use remote profiles.json URL |
| `--check-update` | Check for updates without installing |
| `--update` | Update script to latest version |
| `--allow-hooks` | Enable hook scripts execution |
| `--resume` / `--no-resume` | Resume interrupted installation |
| `--help` | Show help |

## Hook Scripts

Hooks allow running custom scripts at different stages of installation:

```json
{
  "hooks": {
    "pre_install": "/path/to/pre_install.sh",
    "pre_software": "/path/to/pre_software.sh",
    "post_software": "/path/to/post_software.sh",
    "post_install": "/path/to/post_install.sh"
  }
}
```

**Hook types:**
- `pre_install` — Before installation starts
- `pre_software` — Before each software install
- `post_software` — After each software install
- `post_install` — After all installations complete

**Enable with:** `--allow-hooks` (disabled by default for safety)

## Multi-language Support

Manual language selection with arrow key navigation:

🇺🇸 English · 🇨🇳 简体中文 · 🧡 繁體中文 · 🇯🇵 日本語 · 🇰🇷 한국어 · 🇩🇪 Deutsch · 🇫🇷 Français · 🇸🇦 العربية · 🇧🇷 Português · 🇮🇹 Italiano

Use `--lang XX` to skip the language selection menu.

## Supported Package Managers

| Platform | Package Manager | Installation |
|----------|-----------------|--------------|
| Windows | winget | Built-in (requires App Installer) |
| macOS | Homebrew | Auto-install |
| Linux | apt | Built-in (Ubuntu/Debian) |
| Linux | dnf | Built-in (Fedora/RHEL) |
| Linux | pacman | Built-in (Arch/Manjaro) |

## Contributing

Issues and Pull Requests are welcome!

### Adding New Software

1. Edit `config/software/<category>.json` (e.g., `browsers.json`)
2. Add software entry with install commands and check commands
3. Add the software key to the relevant profile in `config/profiles.json`
4. Run `bash scripts/build.sh` to merge
5. Submit PR

### Adding New Profiles

1. Add new profile in `config/profiles.json` `"profiles"` section
2. Run `bash scripts/build.sh`
3. Submit PR

## License

[MIT](LICENSE)

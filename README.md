# Quickstart-PC

> One-click computer setup - Supports Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**Other Languages**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## Features

- 🚀 **One-click install** - Set up your new computer with one command
- 🎯 **Pre-built profiles** - 5 curated profiles for different needs
- 🌐 **Cross-platform** - Supports Windows / macOS / Linux
- ☁️ **Remote config** - Fetch latest config from the cloud
- 📦 **Package manager** - Auto-detect and install package managers
- 🌍 **Multi-language** - Manual language selection, supports English/Chinese

## Quick Start

### macOS / Linux (Recommended)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# Method 1: Download and run
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# Method 2: One-liner
powershell -ExecutionPolicy Bypass -Command "iwr https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1 | iex"
```

## Profiles

| Profile | Description | Included Software |
|---------|-------------|-------------------|
| ⭐ Recommended | Balanced, suitable for most users | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 AI Powered | AI CLI tools, intelligent IDEs | Cursor, Ollama, LM Studio |
| 📊 Office Suite | Documents, spreadsheets, collaboration | WPS, Obsidian, Notion |
| 💻 Developer | IDEs, version control, runtimes | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 Media | Audio/video processing tools | VLC, OBS Studio |

## Project Structure

```
Quickstart-PC/
├── src/
│   ├── quickstart.sh       # Bash source code (develop here)
│   └── quickstart.ps1      # PowerShell source code (develop here)
├── dist/
│   ├── quickstart.sh       # Built Bash artifact (don't edit directly)
│   └── quickstart.ps1      # Built PowerShell artifact (don't edit directly)
├── scripts/
│   └── build.sh            # Build script (injects version)
├── config/
│   └── profiles.json       # Software profiles config (JSON)
├── VERSION                 # Single source of truth for version
├── README.md               # English documentation
└── README.zh-CN.md         # Chinese documentation
```

### Development Workflow

```bash
# Edit source files
nano src/quickstart.sh
nano src/quickstart.ps1

# Build both dist files
bash scripts/build.sh

# Test locally
bash dist/quickstart.sh --list-profiles
```


## Multi-language Support

Manual language selection with arrow key navigation:

- 🇺🇸 English (en-US)
- 🇨🇳 简体中文 (zh-CN)
- 🧡 繁體中文 (zh-Hant)
- 🇯🇵 日本語 (ja)
- 🇰🇷 한국어 (ko)
- 🇩🇪 Deutsch (de)
- 🇫🇷 Français (fr)
- 🇸🇦 العربية (ar)
- 🇧🇷 Português (pt)
- 🇮🇹 Italiano (it)

Use `--lang zh`, `--lang zh-Hant`, `--lang ja`, `--lang ko`, `--lang de`, `--lang fr`, `--lang ar`, `--lang pt`, `--lang it` or `--lang en` to skip the language selection menu.

## Custom Configuration

### Remote Configuration (Default)

The script automatically fetches config from:
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### Custom Remote URL

```bash
quickstart.sh --cfg-url https://your-server.com/profiles.json
```

### Local Configuration

```bash
quickstart.sh --cfg-path /path/to/profiles.json
```

### JSON Config Format

```json
{
  "profiles": {
    "my_custom": {
      "name": "My Profile",
      "desc": "Custom software combination",
      "icon": "🎮",
      "includes": ["chrome", "vscode"]
    }
  },
  "software": {
    "chrome": {
      "name": "Chrome",
      "desc": "Browser",
      "win": "winget install Google.Chrome",
      "mac": "brew install --cask google-chrome",
      "linux": "sudo apt install -y google-chrome-stable",
      "linux_dnf": "sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm",
      "linux_pacman": "yay -S google-chrome",
      "check_win": "winget list Google.Chrome",
      "check_mac": "ls /Applications/Google\\ Chrome.app 2>/dev/null",
      "check_linux": "which google-chrome-stable 2>/dev/null"
    }
  }
}
```

## Command Line Options

| Option | Description |
|--------|-------------|
| `--lang LANG` | Set language (en, zh) |
| `--dev` | Dev mode: show selections without installing |
| `--dry-run` | Fake install: show process without installing |
| `--yes` / `-y` | Auto-confirm all prompts |
| `--verbose` | Show detailed debug info |
| `--log-file FILE` | Write logs to file |
| `--export-plan FILE` | Export installation plan to file |
| `--custom` | Custom software selection mode (manual selection) |
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
| `--version` / `-v` | Show version information |
| `--help` | Show help |

## Supported Package Managers

| Platform | Package Manager | Installation |
|----------|-----------------|--------------|
| Windows | winget | Built-in (requires App Installer) |
| macOS | Homebrew | Auto-install |
| Linux | apt | Built-in (Ubuntu/Debian) |
| Linux | dnf | Built-in (Fedora/RHEL) |
| Linux | pacman | Built-in (Arch/Manjaro) |

## Troubleshooting

### Windows

**"Execution Policy" error:**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

**"winget not found":**
- Install App Installer from Microsoft Store
- Or run `winget` in a new terminal after installation

**"PowerShell 5.1 required":**
- Windows 10+ includes PowerShell 5.1 by default
- Check version: `$PSVersionTable.PSVersion`

### macOS

**"brew not found":**
- The script will auto-install Homebrew
- Or manually: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied":**
- Run with `bash` prefix: `bash quickstart.sh`

### Linux

**"apt not found":**
- The script auto-detects `apt`, `dnf`, or `pacman`
- For unsupported distros, use `--cfg-path` with custom commands

## Contributing

Issues and Pull Requests are welcome!

### Adding New Software

1. Edit `config/profiles.json`
2. Add software entry in `"software"` section
3. Add software key to the profile's `"includes"` array
4. Submit PR

### Adding New Profiles

1. Edit `config/profiles.json`
2. Add new profile in `"profiles"` section
3. Submit PR

## License

[MIT](LICENSE)

# Quickstart-PC

> One-click computer setup - Supports Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**Other Languages**: English | [简体中文](README.zh-CN.md)

## Features

- 🚀 **One-click install** - Set up your new computer with one command
- 🎯 **Pre-built profiles** - 5 curated profiles for different needs
- 🌐 **Cross-platform** - Supports Windows / macOS / Linux
- ☁️ **Remote config** - Fetch latest config from the cloud
- 📦 **Package manager** - Auto-detect and install package managers
- 🌍 **Multi-language** - Manual language selection, supports English/Chinese

## Quick Start

### One-liner (Recommended)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# Download script
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"

# Run (requires admin privileges)
.\quickstart.ps1
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
├── dist/
│   └── quickstart.sh       # Single-file version (recommended)
├── config/
│   └── profiles.json       # Software profiles config (JSON)
├── README.md               # English documentation
└── README.zh-CN.md         # Chinese documentation
```

## Multi-language Support

Manual language selection with arrow key navigation:

- 🇺🇸 English (en-US)
- 🇨🇳 简体中文 (zh-CN)

Use `--lang zh` or `--lang en` to skip the language selection menu.

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
| `--fake-install` / `--dry-run` | Fake install: show process without installing |
| `--yes` / `-y` | Auto-confirm all prompts |
| `--cfg-path PATH` | Use local profiles.json |
| `--cfg-url URL` | Use remote profiles.json URL |
| `--help` | Show help |

## Supported Package Managers

| Platform | Package Manager | Installation |
|----------|-----------------|--------------|
| Windows | winget | Built-in (requires App Installer) |
| macOS | Homebrew | Auto-install |
| Linux | apt | Built-in |

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

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
- 🌍 **Multi-language** - Auto-detect system language, supports English/Chinese

## Quick Start

### Linux / macOS

```bash
curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh | bash
```

Or download and run manually:

```bash
curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh -o quickstart.sh
chmod +x quickstart.sh
./quickstart.sh
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
├── quickstart.sh           # Linux/macOS entry
├── quickstart.ps1          # Windows entry
├── build.sh                # Build single file version
├── config/
│   └── profiles.yaml       # Software profiles config
├── languages/
│   ├── loader.sh           # Language loader
│   ├── en-US.sh            # English language pack
│   └── zh-CN.sh            # Chinese language pack
├── scripts/
│   ├── detect.sh/ps1       # System detection
│   ├── menu.sh/ps1         # Interactive menu
│   └── install.sh/ps1      # Installation logic
└── utils/
    └── log.sh/ps1          # Log utilities
```

## Multi-language Support

The script automatically detects your system language and displays the interface in the appropriate language:

- 🇺🇸 English (en-US)
- 🇨🇳 简体中文 (zh-CN)

### Adding a New Language

1. Create a language file in `languages/` directory, e.g., `ja-JP.sh`
2. Copy the content from `en-US.sh` and translate
3. Add language detection logic in `languages/loader.sh`

## Custom Configuration

### Remote Configuration

Modify the `CONFIG_URL` variable in the first 10 lines of the script:

```bash
# quickstart.sh (line 6)
CONFIG_URL="https://raw.githubusercontent.com/your-repo/config/profiles.yaml"

# quickstart.ps1 (line 14)
$CONFIG_URL = "https://raw.githubusercontent.com/your-repo/config/profiles.yaml"
```

### Local Configuration

Edit `config/profiles.yaml` to add new software or profiles:

```yaml
profiles:
  my_custom:
    name: "My Profile"
    desc: "Custom software combination"
    icon: "🎮"
    includes:
      - browser.chrome
      - devtools.vscode

software:
  browser.chrome:
    name: "Chrome"
    win: "winget install Google.Chrome"
    mac: "brew install --cask google-chrome"
    linux: "sudo apt install -y google-chrome-stable"
```

### Build Single File Version

```bash
chmod +x build.sh
./build.sh
```

The generated single file is at `dist/quickstart.sh`, which can be used for curl pipe installation.

## Supported Package Managers

| Platform | Package Manager | Installation |
|----------|-----------------|--------------|
| Windows | winget | Built-in (requires App Installer) |
| Windows | scoop | Auto-install |
| Windows | chocolatey | Auto-install |
| macOS | Homebrew | Auto-install |
| Linux | apt | Built-in |
| Linux | yum/dnf | Built-in |
| Linux | pacman | Built-in |

## Contributing

Issues and Pull Requests are welcome!

### Adding New Software

1. Edit `config/profiles.yaml`
2. Add software config in `software:` section
3. Add software name to the profile's `includes:` list
4. Submit PR

### Adding New Profiles

1. Edit `config/profiles.yaml`
2. Add new profile in `profiles:` section
3. Submit PR

## License

[MIT](LICENSE)

# Quickstart-PC

> 一鍵設定新電腦軟件環境 - 支援 Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**其他語言**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## 功能

- 🚀 **一鍵安裝** - 一條指令搞定新電腦軟件配置
- 🎯 **預設預設** - 5 個精選預設，滿足不同需求
- 🌐 **全平台支援** - Windows / macOS / Linux 全覆蓋
- ☁️ **雲端配置** - 支援從雲端獲取最新軟件配置
- 📦 **套件管理器** - 自動偵測並安裝套件管理器
- 🌍 **多語言** - 手動選擇語言，支援多種語言

## 快速開始

### 單行指令（推薦）

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# 方式一：下載後執行
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# 方式二：一鍵執行
powershell -ExecutionPolicy Bypass -Command "[System.Text.Encoding]::UTF8.GetString((New-Object System.Net.WebClient).DownloadData('https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1'))|iex"
```

## 預設預設

| 預設 | 說明 | 包含軟件 |
|------|------|----------|
| ⭐ 推薦預設 | 綜合均衡，適合大多數用戶 | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 AI 賦能 | AI CLI 工具、智能 IDE | Cursor, Ollama, LM Studio |
| 📊 辦公套件 | 文件、表格、協作工具 | WPS, Obsidian, Notion |
| 💻 開發者預設 | IDE、版本控制、執行環境 | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 媒體創作 | 音視訊處理工具 | VLC, OBS Studio |

## 項目結構

```
Quickstart-PC/
├── src/
│   └── quickstart.sh       # 原始碼（在這裡開發）
├── dist/
│   └── quickstart.sh       # 建構產物（不要直接編輯）
├── scripts/
│   └── build.sh            # 建構腳本
├── config/
│   └── profiles.json       # 軟件預設配置（JSON）
├── README.md               # 英文文件
└── README.zh-Hant.md       # 繁體中文文件
```

### 開發流程

```bash
# 編輯原始碼
nano src/quickstart.sh

# 建構到 dist
bash scripts/build.sh

# 本地測試
bash dist/quickstart.sh --list-profiles
```

## 多語言支援

手動選擇語言，方向鍵導航：

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

使用 `--lang zh-Hant`、`--lang de`、`--lang fr`、`--lang ar`、`--lang pt`、`--lang it` 或 `--lang en` 跳過語言選擇選單。

## 自訂配置

### 雲端配置（預設）

腳本自動從以下位置獲取配置：
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### 自訂遠端 URL

```bash
quickstart.sh --cfg-url https://your-server.com/profiles.json
```

### 本地配置

```bash
quickstart.sh --cfg-path /path/to/profiles.json
```

### JSON 配置格式

```json
{
  "profiles": {
    "my_custom": {
      "name": "我的預設",
      "desc": "自訂軟件組合",
      "icon": "🎮",
      "includes": ["chrome", "vscode"]
    }
  },
  "software": {
    "chrome": {
      "name": "Chrome",
      "desc": "瀏覽器",
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

## 命令列參數

| 參數 | 說明 |
|------|------|
| `--lang LANG` | 設定語言 |
| `--dev` | 開發模式：顯示選擇但不安裝 |
| `--dry-run` | 假裝安裝：展示過程但不實際安裝 |
| `--yes` / `-y` | 自動確認所有提示 |
| `--verbose` | 顯示詳細調試資訊 |
| `--log-file FILE` | 將日誌寫入檔案 |
| `--export-plan FILE` | 匯出安裝計劃到檔案 |
| `--custom` | 自訂軟件選擇模式（手動選擇） |
| `--retry-failed` | 重試之前失敗的軟件 |
| `--list-profiles` | 列出所有可用預設 |
| `--cfg-url URL` | 使用遠程 profiles.json URL |
| `--version` / `-v` | 顯示版本信息 |
| `--help` | 顯示說明 |

## 支援的套件管理器

| 平台 | 套件管理器 | 安裝方式 |
|------|----------|----------|
| Windows | winget | 系統自帶（需安裝 App Installer） |
| macOS | Homebrew | 自動安裝 |
| Linux | apt | 系統自帶（Ubuntu/Debian） |
| Linux | dnf | 系統自帶（Fedora/RHEL） |
| Linux | pacman | 系統自帶（Arch/Manjaro） |

## 故障排除

### Windows

**「執行策略」錯誤：**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

或者臨時繞過：
```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

**「winget 未找到」：**
- 從 Microsoft Store 安裝 App Installer
- 安裝後需打開新終端才能使用 `winget`
- 檢查版本：`winget --version`

**「PowerShell 版本過低」：**
- Windows 10+ 預設包含 PowerShell 5.1
- 檢查版本：`$PSVersionTable.PSVersion`
- 如需升級：安裝 [PowerShell 7+](https://github.com/PowerShell/PowerShell)

### macOS

**「brew 未找到」：**
- 腳本會自動安裝 Homebrew
- 或手動安裝：`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**「Permission denied」：**
- 使用 `bash` 前綴執行：`bash quickstart.sh`

### Linux

**「apt 未找到」：**
- 本腳本支援基於 apt 的發行版（Ubuntu/Debian）
- 其他發行版可使用 `--cfg-path` 自訂指令

## 貢獻

歡迎提交 Issue 和 Pull Request！

### 新增軟件

1. 編輯 `config/profiles.json`
2. 在 `"software"` 部分新增軟件配置
3. 在對應預設的 `"includes"` 陣列中新增軟件 key
4. 提交 PR

### 新增預設

1. 編輯 `config/profiles.json`
2. 在 `"profiles"` 部分新增新預設
3. 提交 PR

## 許可證

[MIT](LICENSE)
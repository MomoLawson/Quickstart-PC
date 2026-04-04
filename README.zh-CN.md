# Quickstart-PC

> 一键配置新电脑软件环境 - 支持 Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**其他语言**: [English](README.md) | 简体中文

## 特性

- 🚀 **一键安装** - 一条命令搞定新电脑软件配置
- 🎯 **预设套餐** - 5 个精选套餐，满足不同需求
- 🌐 **全平台支持** - Windows / macOS / Linux 全覆盖
- ☁️ **云端配置** - 支持从云端获取最新软件配置
- 📦 **包管理器** - 自动检测并安装包管理器
- 🌍 **多语言** - 手动选择语言，支持中文/英文

## 快速开始

### 单行命令（推荐）

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# 下载脚本
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"

# 运行（需要管理员权限）
.\quickstart.ps1
```

## 预设套餐

| 套餐 | 说明 | 包含软件 |
|------|------|----------|
| ⭐ 推荐套餐 | 综合均衡，适合大多数用户 | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 AI 赋能 | AI CLI 工具、智能 IDE | Cursor, Ollama, LM Studio |
| 📊 办公套件 | 文档、表格、协作工具 | WPS, Obsidian, Notion |
| 💻 开发者套餐 | IDE、版本控制、运行时环境 | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 媒体创作 | 音视频处理工具 | VLC, OBS Studio |

## 项目结构

```
Quickstart-PC/
├── src/
│   └── quickstart.sh       # 源代码（在这里开发）
├── dist/
│   └── quickstart.sh       # 构建产物（不要直接编辑）
├── scripts/
│   └── build.sh            # 构建脚本
├── config/
│   └── profiles.json       # 软件套餐配置（JSON）
├── README.md               # 英文文档
└── README.zh-CN.md         # 中文文档
```

### 开发流程

```bash
# 编辑源码
nano src/quickstart.sh

# 构建到 dist
bash scripts/build.sh

# 本地测试
bash dist/quickstart.sh --list-profiles
```

## 多语言支持

手动选择语言，方向键导航：

- 🇺🇸 English (en-US)
- 🇨🇳 简体中文 (zh-CN)

使用 `--lang zh` 或 `--lang en` 跳过语言选择菜单。

## 自定义配置

### 云端配置（默认）

脚本自动从以下地址获取配置：
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### 自定义远程 URL

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
      "name": "我的套餐",
      "desc": "自定义软件组合",
      "icon": "🎮",
      "includes": ["chrome", "vscode"]
    }
  },
  "software": {
    "chrome": {
      "name": "Chrome",
      "desc": "浏览器",
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

## 命令行参数

| 参数 | 说明 |
|------|------|
| `--lang LANG` | 设置语言 (en, zh) |
| `--dev` | 开发模式：显示选择但不安装 |
| `--dry-run` | 假装安装：展示过程但不实际安装 |
| `--yes` / `-y` | 自动确认所有提示 |
| `--verbose` / `-v` | 显示详细调试信息 |
| `--log-file FILE` | 将日志写入文件 |
| `--export-plan FILE` | 导出安装计划到文件 |
| `--custom` | 自定义软件选择模式（手动选择） |
| `--retry-failed` | 重试之前失败的软件 |
| `--list-profiles` | 列出所有可用套餐 |
| `--cfg-url URL` | 使用远程 profiles.json URL |
| `--help` | 显示帮助 |

## 支持的包管理器

| 平台 | 包管理器 | 安装方式 |
|------|----------|----------|
| Windows | winget | 系统自带（需安装 App Installer） |
| macOS | Homebrew | 自动安装 |
| Linux | apt | 系统自带 |

## 故障排除

### Windows

**"执行策略" 错误：**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

或者临时绕过：
```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

**"winget 未找到"：**
- 从 Microsoft Store 安装 App Installer
- 安装后需打开新终端才能使用 `winget`
- 检查版本：`winget --version`

**"PowerShell 版本过低"：**
- Windows 10+ 默认包含 PowerShell 5.1
- 检查版本：`$PSVersionTable.PSVersion`
- 如需升级：安装 [PowerShell 7+](https://github.com/PowerShell/PowerShell)

**中文终端乱码：**
- 确保 PowerShell 使用 UTF-8 编码
- 运行：`[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`

### macOS

**"brew 未找到"：**
- 脚本会自动安装 Homebrew
- 或手动安装：`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied"：**
- 使用 `bash` 前缀运行：`bash quickstart.sh`

### Linux

**"apt 未找到"：**
- 本脚本支持基于 apt 的发行版（Ubuntu/Debian）
- 其他发行版可使用 `--cfg-path` 自定义命令

## 贡献

欢迎提交 Issue 和 Pull Request！

### 添加新软件

1. 编辑 `config/profiles.json`
2. 在 `"software"` 部分添加软件配置
3. 在对应套餐的 `"includes"` 数组中添加软件 key
4. 提交 PR

### 添加新套餐

1. 编辑 `config/profiles.json`
2. 在 `"profiles"` 部分添加新套餐
3. 提交 PR

## 许可证

[MIT](LICENSE)

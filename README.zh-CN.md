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
- 🌍 **多语言** - 自动检测系统语言，支持中文/英文

## 快速开始

### Linux / macOS（推荐）

```bash
# 下载并运行
curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh -o quickstart.sh
chmod +x quickstart.sh
./quickstart.sh
```

### 其他方式（单行命令）

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
├── quickstart.sh           # Linux/macOS 入口
├── quickstart.ps1          # Windows 入口
├── build.sh                # 构建单文件版本
├── config/
│   └── profiles.yaml       # 软件套餐配置
├── languages/
│   ├── loader.sh           # 语言加载器
│   ├── en-US.sh            # 英文语言包
│   └── zh-CN.sh            # 中文语言包
├── scripts/
│   ├── detect.sh/ps1       # 系统检测
│   ├── menu.sh/ps1         # 交互菜单
│   └── install.sh/ps1      # 安装逻辑
└── utils/
    └── log.sh/ps1          # 日志工具
```

## 多语言支持

脚本会自动检测系统语言并使用对应的语言界面：

- 🇺🇸 English (en-US)
- 🇨🇳 简体中文 (zh-CN)

### 添加新语言

1. 在 `languages/` 目录创建语言文件，如 `ja-JP.sh`
2. 复制 `en-US.sh` 的内容并翻译
3. 在 `languages/loader.sh` 中添加语言检测逻辑

## 自定义配置

### 云端配置

修改脚本前 10 行的 `CONFIG_URL` 变量：

```bash
# quickstart.sh (第 6 行)
CONFIG_URL="https://raw.githubusercontent.com/your-repo/config/profiles.yaml"
```

### 本地配置

编辑 `config/profiles.yaml` 添加新软件或套餐：

```yaml
profiles:
  my_custom:
    name: "我的套餐"
    desc: "自定义软件组合"
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

### 构建单文件版本

```bash
chmod +x build.sh
./build.sh
```

生成的单文件版本在 `dist/quickstart.sh`，可以用于 curl 管道安装。

## 支持的包管理器

| 平台 | 包管理器 | 安装方式 |
|------|----------|----------|
| Windows | winget | 系统自带（需安装 App Installer） |
| Windows | scoop | 自动安装 |
| Windows | chocolatey | 自动安装 |
| macOS | Homebrew | 自动安装 |
| Linux | apt | 系统自带 |
| Linux | yum/dnf | 系统自带 |
| Linux | pacman | 系统自带 |

## 贡献

欢迎提交 Issue 和 Pull Request！

### 添加新软件

1. 编辑 `config/profiles.yaml`
2. 在 `software:` 部分添加软件配置
3. 在对应套餐的 `includes:` 中添加软件名
4. 提交 PR

### 添加新套餐

1. 编辑 `config/profiles.yaml`
2. 在 `profiles:` 部分添加新套餐
3. 提交 PR

## 许可证

[MIT](LICENSE)

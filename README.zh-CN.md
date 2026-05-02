# Quickstart-PC

> 一键配置新电脑软件环境 - 支持 Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()
[![Version](https://img.shields.io/badge/version-0.82.1-green.svg)](VERSION)

**其他语言**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## 特性

- 🚀 **一键安装** - 一条命令搞定新电脑软件配置
- 🎯 **12 个预设套餐** - 精选套餐满足不同需求
- 🌐 **全平台支持** - Windows / macOS / Linux 全覆盖
- ☁️ **云端配置** - 支持从云端获取最新软件配置
- 📦 **包管理器** - 自动检测并安装包管理器
- 🌍 **多语言** - 10 种语言手动选择
- 🔧 **环境诊断** - `doctor` 命令检测系统环境
- 🔄 **自动更新** - 启动时检查更新，Ctrl+U 一键更新
- 🪝 **钩子脚本** - 安装前后执行自定义脚本

## 快速开始

### macOS / Linux（Bash）

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows（PowerShell）

```powershell
# 方式一：下载后运行
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# 方式二：一键运行
powershell -ExecutionPolicy Bypass -Command "[System.Text.Encoding]::UTF8.GetString((New-Object System.Net.WebClient).DownloadData('https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1'))|iex"
```

## Bash 与 PowerShell 对比

| 功能 | Bash (`quickstart.sh`) | PowerShell (`quickstart.ps1`) |
|------|----------------------|-------------------------------|
| 平台 | macOS, Linux | Windows, macOS, Linux |
| 语言加载 | `source` .sh 文件 | JSON 文件 + `ConvertFrom-Json` |
| 版本参数 | `--version` / `-v` | `-showVersion` / `-sv` |
| 环境诊断 | `doctor` / `doctor --fix` | `doctor` / `doctor -fix` |
| 更新提示 | TUI 中 `Ctrl+U` | TUI 中 `Ctrl+U` |
| 配置解析 | `jq`（主）/ `python3`（备选） | 原生 `ConvertFrom-Json` |
| TUI 输入 | `read -rsn1` + 按键码 | `[Console]::ReadKey()` |

## 预设套餐

| 套餐 | 说明 | 包含软件 |
|------|------|----------|
| ⭐ 推荐套餐 | 综合均衡，适合大多数用户 | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 AI 赋能 | AI CLI 工具、智能 IDE | Cursor, Ollama, LM Studio |
| 📊 办公套件 | 文档、表格、协作工具 | WPS, Obsidian, Notion |
| 💻 开发者套餐 | IDE、版本控制、运行时环境 | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 媒体创作 | 音视频处理工具 | VLC, OBS Studio |
| 💬 通讯社交 | 聊天和即时通讯应用 | Discord, Slack, Telegram |
| 🔒 安全工具 | 安全和隐私工具 | 1Password, Bitwarden |
| 🍎 macOS 效率 | macOS 专用效率工具 | Rectangle, Karabiner |
| 🔧 实用工具 | 通用工具软件 | Notepad++, 7-Zip |
| 🗄️ 数据库 | 数据库管理工具 | DBeaver, pgAdmin |
| ⬛ 终端工具 | 终端模拟器和工具 | iTerm2, Windows Terminal |
| 🇨🇳 国内软件 | 国内常用软件 | 微信, QQ, WPS |

## 项目结构

```
Quickstart-PC/
├── src/                        # 源代码（在这里编辑）
│   ├── quickstart.sh           # Bash 实现
│   ├── quickstart.ps1          # PowerShell 实现
│   └── lang/                   # 语言文件
│       ├── en-US.sh            # Bash：shell 变量（source 加载）
│       ├── en-US.json          # PS1：JSON 格式（动态加载）
│       ├── zh-CN.sh / .json    # 10 种语言 × 2 种格式
│       └── ...
├── dist/                       # 构建产物（不要直接编辑）
│   ├── quickstart.sh
│   ├── quickstart.ps1
│   └── lang/
├── config/
│   ├── profiles.json           # 合并后的配置（构建时自动合并）
│   └── software/               # 分类软件 JSON 文件
├── scripts/
│   ├── build.sh                # 合并软件 JSON + 注入版本号
│   └── release.sh              # 版本升级 → 构建 → 提交 → 标签 → 发布
├── .github/workflows/
│   ├── quality.yml             # CI：shellcheck + PS 语法 + JSON + 构建 + 冒烟测试
│   └── release.yml             # CD：手动触发 → 升版 → 构建 → 发布
├── VERSION                     # 版本号唯一来源（0.82.1）
└── AGENTS.md                   # AI 代理知识库
```

## 命令行参数

| 参数 | 说明 |
|------|------|
| `--lang LANG` | 设置语言 (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it) |
| `doctor` | 运行 QC Doctor 环境诊断 |
| `doctor --fix` | 自动修复缺失的依赖项 |
| `--dev` | 开发模式：显示选择但不安装 |
| `--dry-run` | 预览模式：展示过程但不实际安装 |
| `--yes` / `-y` | 自动确认所有提示 |
| `--verbose` | 显示详细调试信息 |
| `--version` / `-v` | 显示版本信息（仅 Bash） |
| `--log-file FILE` | 将日志写入文件 |
| `--export-plan FILE` | 导出安装计划到文件 |
| `--retry-failed` | 重试之前失败的软件 |
| `--list-profiles` | 列出所有可用套餐 |
| `--show-profile KEY` | 显示指定套餐详情 |
| `--skip SW` | 跳过指定软件（可多次使用） |
| `--only SW` | 只安装指定软件（可多次使用） |
| `--fail-fast` | 遇到错误时立即停止 |
| `--profile NAME` | 直接指定安装套餐（跳过选择菜单） |
| `--non-interactive` | 非交互模式（禁止所有 TUI/prompt） |
| `--cfg-path PATH` | 使用本地 profiles.json 文件 |
| `--cfg-url URL` | 使用远程 profiles.json URL |
| `--check-update` | 检查更新但不安装 |
| `--update` | 更新脚本到最新版本 |
| `--allow-hooks` | 启用钩子脚本执行 |
| `--resume` / `--no-resume` | 恢复中断的安装 |
| `--help` | 显示帮助 |

## 钩子脚本

钩子允许在安装的不同阶段运行自定义脚本：

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

**钩子类型：**
- `pre_install` — 开始安装前
- `pre_software` — 每个软件安装前
- `post_software` — 每个软件安装后
- `post_install` — 全部安装完成后

**启用方式：** `--allow-hooks`（默认禁用，安全起见）

## 多语言支持

手动选择语言，方向键导航：

🇺🇸 English · 🇨🇳 简体中文 · 🧡 繁體中文 · 🇯🇵 日本語 · 🇰🇷 한국어 · 🇩🇪 Deutsch · 🇫🇷 Français · 🇸🇦 العربية · 🇧🇷 Português · 🇮🇹 Italiano

使用 `--lang XX` 跳过语言选择菜单。

## 支持的包管理器

| 平台 | 包管理器 | 安装方式 |
|------|----------|----------|
| Windows | winget | 系统自带（需安装 App Installer） |
| macOS | Homebrew | 自动安装 |
| Linux | apt | 系统自带（Ubuntu/Debian） |
| Linux | dnf | 系统自带（Fedora/RHEL） |
| Linux | pacman | 系统自带（Arch/Manjaro） |

## 贡献

欢迎提交 Issue 和 Pull Request！

### 添加新软件

1. 编辑 `config/software/<分类>.json`（如 `browsers.json`）
2. 添加软件配置，包含安装命令和检测命令
3. 在 `config/profiles.json` 的对应套餐中添加软件 key
4. 运行 `bash scripts/build.sh` 合并配置
5. 提交 PR

### 添加新套餐

1. 在 `config/profiles.json` 的 `"profiles"` 部分添加新套餐
2. 运行 `bash scripts/build.sh`
3. 提交 PR

## 许可证

[MIT](LICENSE)

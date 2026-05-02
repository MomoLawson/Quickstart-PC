# Quickstart-PC

> ワンクリックでPCを設定 - Windows / macOS / Linux 対応

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**他の言語**:  [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | 日本語 | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## 機能

- 🚀 **ワンクリックインストール** - 1つのコマンドで新PCを設定
- 🎯 **プリセットプロファイル** - ニーズ別の5つのプロファイル
- 🌐 **クロスプラットフォーム** - Windows / macOS / Linux 対応
- ☁️ **リモート設定** - クラウドから最新設定を取得
- 📦 **パッケージマネージャー** - パッケージマネージャーを自動検出・インストール
- 🌍 **多言語対応** - 言語選択可能（英語/中国語/日本語/韓国語）

## クイックスタート

### macOS / Linux (推奨)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# 方法1: ダウンロードして実行
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# 方法2: ワンライナー
powershell -ExecutionPolicy Bypass -Command "[System.Text.Encoding]::UTF8.GetString((New-Object System.Net.WebClient).DownloadData('https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1'))|iex"
```

## プロファイル

| プロファイル | 説明 | 含まれるソフトウェア |
|-------------|------|---------------------|
| ⭐ 推奨 | バランス型、一般的なユーザーに最適 | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 AI搭載 | AI CLIツール、智能IDE | Cursor, Ollama, LM Studio |
| 📊 オフィススイート | ドキュメント、スプレッドシート、コラボレーション | WPS, Obsidian, Notion |
| 💻 开发者 | IDE、バージョン管理、ランタイム | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 メディア | 音声/動画處理ツール | VLC, OBS Studio |

## プロジェクト構造

```
Quickstart-PC/
├── src/
│   ├── quickstart.sh       # Bashソースコード（ここで開発）
│   └── quickstart.ps1      # PowerShellソースコード（ここで開発）
├── dist/
│   ├── quickstart.sh       # ビルドされたBash（アーティファクト、直接編集不可）
│   └── quickstart.ps1      # ビルドされたPowerShell（アーティファクト、直接編集不可）
├── scripts/
│   └── build.sh            # ビルドスクリプト（バージョンを注入）
├── config/
│   └── profiles.json       # ソフトウェアプロファイル設定（JSON）
├── VERSION                 # バージョンの単一情報源
├── README.md               # 英語ドキュメント
├── README.zh-CN.md         # 中国語ドキュメント
├── README.ja.md            # 日本語ドキュメント
└── README.ko.md            # 韓国語ドキュメント
```

### 開発ワークフロー

```bash
# ソースファイルを編集
nano src/quickstart.sh
nano src/quickstart.ps1

# 両方をビルド
bash scripts/build.sh

# ローカルでテスト
bash dist/quickstart.sh --list-profiles
```

## 多言語対応

矢印キーで言語を選択：

- 🇺🇸 English (en-US)
- 🇨🇳 简体中文 (zh-CN)
- 🇯🇵 日本語 (ja)
- 🇰🇷 한국어 (ko)

`--lang ja`、`--lang ko`、`--lang zh`、`--lang en` で言語選択メニューをスキップできます。

## カスタム設定

### リモート設定（デフォルト）

スクリプトは以下のURLから設定を自動取得：
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### カスタムリモートURL

```bash
quickstart.sh --cfg-url https://your-server.com/profiles.json
```

### ローカル設定

```bash
quickstart.sh --cfg-path /path/to/profiles.json
```

### JSON設定フォーマット

```json
{
  "profiles": {
    "my_custom": {
      "name": "マイプロファイル",
      "desc": "カスタムソフトウェアの組み合わせ",
      "icon": "🎮",
      "includes": ["chrome", "vscode"]
    }
  },
  "software": {
    "chrome": {
      "name": "Chrome",
      "desc": "ブラウザ",
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

## コマンドラインオプション

| オプション | 説明 |
|-----------|------|
| `--lang LANG` | 言語を設定 (en, zh, ja, ko) |
| `--dev` | 開発モード: 選択を表示但不インストール |
| `--dry-run` | 假装インストール: 过程を表示但不実際インストール |
| `--yes` / `-y` | 全てのプロンプトに自動同意 |
| `--verbose` | 詳細なデバッグ情報を表示 |
| `--log-file FILE` | ログをファイルに書き込む |
| `--export-plan FILE` | インストール計画をエクスポート |
| `--custom` | カスタムソフトウェア選択モード |
| `--retry-failed` | 以前に失敗したパッケージを再試行 |
| `--list-profiles` | 全ての利用可能なプロファイルをリスト表示 |
| `--show-profile KEY` | プロファイルの詳細を表示 |
| `--skip SW` | 指定したソフトウェアをスキップ（重复可能） |
| `--only SW` | 指定したソフトウェアのみインストール（重复可能） |
| `--fail-fast` | 最初のエラーで停止 |
| `--profile NAME` | プロファイルを直接指定 |
| `--non-interactive` | 非インタラクティブモード |
| `--cfg-path PATH` | ローカルのprofiles.jsonを使用 |
| `--cfg-url URL` | リモートのprofiles.json URLを使用 |
| `--version` / `-v` | バージョン情報を表示 |
| `--help` | ヘルプを表示 |

## 対応パッケージマネージャー

| プラットフォーム | パッケージマネージャー | インストール方法 |
|-----------------|----------------------|-----------------|
| Windows | winget | 組み込み（App Installerが必要） |
| macOS | Homebrew | 自動インストール |
| Linux | apt | 組み込み（Ubuntu/Debian） |
| Linux | dnf | 組み込み（Fedora/RHEL） |
| Linux | pacman | 組み込み（Arch/Manjaro） |

## トラブルシューティング

### Windows

**"Execution Policy" エラー:**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

**"winget not found":**
- Microsoft StoreからApp Installerをインストール
- インストール後、新しいターミナルで`winget`を使用

**"PowerShell 5.1 required":**
- Windows 10+ にはデフォルトでPowerShell 5.1が含まれる
- バージョン確認: `$PSVersionTable.PSVersion`

### macOS

**"brew not found":**
- スクリプトがHomebrewを自動インストール
- または手動: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied":**
- `bash` プレフィックスで実行: `bash quickstart.sh`

### Linux

**"apt not found":**
- スクリプトは`apt`、`dnf`、`pacman`を自動検出
- サポートされていないディストロは`--cfg-path`でカスタムコマンドを使用

## コントリビューション

IssueとPull Requestを歓迎します！

### 新しいソフトウェアの追加

1. `config/profiles.json`を編集
2. `"software"`セクションにエントリを追加
3. プロファイルの`"includes"`配列にソフトウェアキーを追加
4. PRを提出

### 新しいプロファイルの追加

1. `config/profiles.json`を編集
2. `"profiles"`セクションに新しいプロファイルを追加
3. PRを提出

## ライセンス

[MIT](LICENSE)

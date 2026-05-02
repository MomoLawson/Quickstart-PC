# Quickstart-PC

> 원클릭 PC 설정 - Windows / macOS / Linux 지원

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**다른 언어**:  [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | 한국어 | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)
## 기능

- 🚀 **원클릭 설치** - 하나의 명령으로 새 PC 설정
- 🎯 **프리셋 프로필** - 요구사항에 맞는 5가지 프로필
- 🌐 **크로스 플랫폼** - Windows / macOS / Linux 지원
- ☁️ **원격 설정** - 클라우드에서 최신 설정 가져오기
- 📦 **패키지 관리자** - 패키지 관리자 자동 감지 및 설치
- 🌍 **다국어 지원** - 언어 선택 가능 (영어/중국어/일본어/한국어)

## 빠른 시작

### macOS / Linux (권장)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# 방법 1: 다운로드 및 실행
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# 방법 2: 원라이너
powershell -ExecutionPolicy Bypass -Command "$bytes = (New-Object System.Net.WebClient).DownloadData('https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1'); iex ([System.Text.Encoding]::UTF8.GetString($bytes))"
```

## 프로필

| 프로필 | 설명 | 포함된 소프트웨어 |
|--------|------|-------------------|
| ⭐ 권장 | 균형 잡힌类型, 대부분의 사용자에게 적합 | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 AI 제공 | AI CLI 도구, 스마트 IDE | Cursor, Ollama, LM Studio |
| 📊 오피스 스위트 | 문서, 스프레드시트, 협업 도구 | WPS, Obsidian, Notion |
| 💻 개발자 | IDE, 버전 관리, 런타임 | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 미디어 | 오디오/비디오 처리 도구 | VLC, OBS Studio |

## 프로젝트 구조

```
Quickstart-PC/
├── src/
│   ├── quickstart.sh       # Bash 소스 코드 (여기서 개발)
│   └── quickstart.ps1      # PowerShell 소스 코드 (여기서 개발)
├── dist/
│   ├── quickstart.sh       # 빌드된 Bash 아티팩트 (직접 편집 불가)
│   └── quickstart.ps1      # 빌드된 PowerShell 아티팩트 (직접 편집 불가)
├── scripts/
│   └── build.sh            # 빌드 스크립트 (버전 주입)
├── config/
│   └── profiles.json       # 소프트웨어 프로필 설정 (JSON)
├── VERSION                 # 단일 버전 정보 원본
├── README.md               # 영어 문서
├── README.zh-CN.md         # 중국어 문서
├── README.ja.md            # 일본어 문서
└── README.ko.md            # 한국어 문서
```

### 개발 워크플로

```bash
# 소스 파일 편집
nano src/quickstart.sh
nano src/quickstart.ps1

# 둘 다 빌드
bash scripts/build.sh

# 로컬 테스트
bash dist/quickstart.sh --list-profiles
```

## 다국어 지원

화살표 키로 언어 선택:

- 🇺🇸 English (en-US)
- 🇨🇳 简体中文 (zh-CN)
- 🇯🇵 日本語 (ja)
- 🇰🇷 한국어 (ko)

`--lang ko`, `--lang ja`, `--lang zh`, `--lang en`을 사용하여 언어 선택 메뉴를 건너뛸 수 있습니다.

## 사용자 정의 설정

### 원격 설정 (기본값)

스크립트가 다음에서 설정을 자동으로 가져옵니다:
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### 사용자 정의 원격 URL

```bash
quickstart.sh --cfg-url https://your-server.com/profiles.json
```

### 로컬 설정

```bash
quickstart.sh --cfg-path /path/to/profiles.json
```

### JSON 설정 형식

```json
{
  "profiles": {
    "my_custom": {
      "name": "내 프로필",
      "desc": "사용자 정의 소프트웨어 조합",
      "icon": "🎮",
      "includes": ["chrome", "vscode"]
    }
  },
  "software": {
    "chrome": {
      "name": "Chrome",
      "desc": "브라우저",
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

## 명령줄 옵션

| 옵션 | 설명 |
|------|------|
| `--lang LANG` | 언어 설정 (en, zh, ja, ko) |
| `--dev` | 개발 모드: 선택 표시但不설치 |
| `--dry-run` | 흉내 설치: 과정 표시，但不실제 설치 |
| `--yes` / `-y` | 모든 프롬프트에 자동 동의 |
| `--verbose` | 자세한 디버그 정보 표시 |
| `--log-file FILE` | 로그를 파일에 쓰기 |
| `--export-plan FILE` | 설치 계획 내보내기 |
| `--custom` | 사용자 정의 소프트웨어 선택 모드 |
| `--retry-failed` | 이전에 실패한 패키지 재시도 |
| `--list-profiles` | 사용 가능한 모든 프로필 나열 |
| `--show-profile KEY` | 프로필 세부 정보 표시 |
| `--skip SW` | 지정한 소프트웨어 건너뛰기 (반복 가능) |
| `--only SW` | 지정한 소프트웨어만 설치 (반복 가능) |
| `--fail-fast` | 첫 번째 오류에서 중지 |
| `--profile NAME` | 프로필 직접 선택 (메뉴 건너뛰기) |
| `--non-interactive` | 비대화형 모드 |
| `--cfg-path PATH` | 로컬 profiles.json 사용 |
| `--cfg-url URL` | 원격 profiles.json URL 사용 |
| `--version` / `-v` | 버전 정보 표시 |
| `--help` | 도움말 표시 |

## 지원되는 패키지 관리자

| 플랫폼 | 패키지 관리자 | 설치 방법 |
|--------|--------------|----------|
| Windows | winget | 기본 제공 (App Installer 필요) |
| macOS | Homebrew | 자동 설치 |
| Linux | apt | 기본 제공 (Ubuntu/Debian) |
| Linux | dnf | 기본 제공 (Fedora/RHEL) |
| Linux | pacman | 기본 제공 (Arch/Manjaro) |

## 문제 해결

### Windows

**"Execution Policy" 오류:**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

**"winget not found":**
- Microsoft Store에서 App Installer 설치
- 설치 후 새 터미널에서 `winget` 사용

**"PowerShell 5.1 required":**
- Windows 10+에는 기본적으로 PowerShell 5.1이 포함되어 있습니다
- 버전 확인: `$PSVersionTable.PSVersion`

### macOS

**"brew not found":**
- 스크립트가 Homebrew를 자동 설치
- 수동 설치: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied":**
- `bash` 접두사로 실행: `bash quickstart.sh`

### Linux

**"apt not found":**
- 스크립트가 `apt`, `dnf`, `pacman`을 자동 감지
- 지원되지 않는 배포판은 `--cfg-path`로 사용자 정의 명령 사용

## 기여

Issue와 Pull Request를 환영합니다!

### 새 소프트웨어 추가

1. `config/profiles.json` 편집
2. `"software"` 섹션에 소프트웨어 항목 추가
3. 프로필의 `"includes"` 배열에 소프트웨어 키 추가
4. PR 제출

### 새 프로필 추가

1. `config/profiles.json` 편집
2. `"profiles"` 섹션에 새 프로필 추가
3. PR 제출

## 라이선스

[MIT](LICENSE)

# Quickstart-PC

> إعداد الكمبيوتر بضغطة واحدة - يدعم Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**اللغات الأخرى**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## المميزات

- 🚀 **تثبيت بضغطة واحدة** - جهّز حاسوبك الجديد بأمر واحد
- 🎯 **ملفات شخصية جاهزة** - 5 ملفات منتقاة لاحتياجات مختلفة
- 🌐 **متعدد المنصات** - يدعم Windows / macOS / Linux
- ☁️ **إعداد عن بُعد** - جلب أحدث الإعدادات من السحابة
- 📦 **مدير الحزم** - اكتشاف وتثبيت مديري الحزم تلقائياً
- 🌍 **متعدد اللغات** - اختيار اللغة يدوياً، عدة لغات مدعومة

## البدء السريع

### macOS / Linux (موصى به)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# الطريقة 1: التحميل والتنفيذ
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# الطريقة 2: سطر واحد
powershell -ExecutionPolicy Bypass -Command "iwr https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1 | iex"
```

## الملفات الشخصية

| الملف | الوصف | البرامج المشمولة |
|------|-------|-------------------|
| ⭐ موصى به | متوازن، مناسب لمعظم المستخدمين | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 ذكاء اصطناعي | أدوات CLI للذكاء الاصطناعي، بيئات تطوير ذكية | Cursor, Ollama, LM Studio |
| 📊 مكتب | مستندات، جداول، تعاون | WPS, Obsidian, Notion |
| 💻 مطور | بيئات تطوير، تحكم بالإصدارات، بيئات تشغيل | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 إعلام | أدوات معالجة الصوت والفيديو | VLC, OBS Studio |

## هيكل المشروع

```
Quickstart-PC/
├── src/
│   ├── quickstart.sh       # كود المصدر Bash (طوّر هنا)
│   └── quickstart.ps1      # كود المصدر PowerShell (طوّر هنا)
├── dist/
│   ├── quickstart.sh       # ناتج Bash (لا تعدله مباشرة)
│   └── quickstart.ps1      # ناتج PowerShell (لا تعدله مباشرة)
├── scripts/
│   └── build.sh            # سكريبت البناء (يُحقن الإصدار)
├── config/
│   └── profiles.json       # إعدادات ملفات البرامج (JSON)
├── VERSION                 # مصدر الحقيقة للإصدار
├── README.md               # التوثيق الإنجليزي
└── README.ar.md            # التوثيق العربي
```

### سير عمل التطوير

```bash
# عدّل ملفات المصدر
nano src/quickstart.sh
nano src/quickstart.ps1

# ابنِ ملفات dist
bash scripts/build.sh

# اختبر محلياً
bash dist/quickstart.sh --list-profiles
```

## دعم اللغات المتعددة

اختيار اللغة يدوياً مع التنقل بأزرار الأسهم:

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

استخدم `--lang ar` أو `--lang en` لتخطي قائمة اختيار اللغة.

## الإعداد المخصص

### الإعداد عن بُعد (الافتراضي)

 السكريبت يجلب الإعدادات تلقائياً من:
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### عنوان URL عن بُعد مخصص

```bash
quickstart.sh --cfg-url https://خادمك.com/profiles.json
```

### الإعداد المحلي

```bash
quickstart.sh --cfg-path /مسار/إلى/profiles.json
```

### تنسيق إعدادات JSON

```json
{
  "profiles": {
    "my_custom": {
      "name": "ملفي",
      "desc": "مجموعة برامج مخصصة",
      "icon": "🎮",
      "includes": ["chrome", "vscode"]
    }
  },
  "software": {
    "chrome": {
      "name": "Chrome",
      "desc": "متصفح",
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

## خيارات سطر الأوامر

| الخيار | الوصف |
|--------|-------|
| `--lang LANG` | تعيين اللغة |
| `--dev` | وضع التطوير: إظهار الاختيارات دون التثبيت |
| `--dry-run` | تثبيت وهمي: إظهار العملية دون التثبيت |
| `--yes` / `-y` | تأكيد جميع المطالبات تلقائياً |
| `--verbose` | إظهار معلومات التصحيح التفصيلية |
| `--log-file FILE` | كتابة السجلات في ملف |
| `--export-plan FILE` | تصدير خطة التثبيت |
| `--custom` | وضع اختيار البرامج المخصص (يدوي) |
| `--retry-failed" إعادة尝试 الحزم الفاشلة سابقاً |
| `--list-profiles` | سرد جميع الملفات الشخصية المتاحة |
| `--show-profile KEY` | إظهار تفاصيل الملف الشخصي |
| `--skip SW` | تخطي البرنامج المحدد (قابل للتكرار) |
| `--only SW` | تثبيت البرنامج المحدد فقط (قابل للتكرار) |
| `--fail-fast` | التوقف عند第一个错误 |
| `--profile NAME` | تحديد الملف الشخصي مباشرة (تخطي القائمة) |
| `--non-interactive` | الوضع غير التفاعلي (لا TUI/مطالبات) |
| `--cfg-path PATH` | استخدام profiles.json المحلي |
| `--cfg-url URL` | استخدام عنوان profiles.json البعيد |
| `--version` / `-v` | إظهار معلومات الإصدار |
| `--help` | إظهار المساعدة |

## مديرو الحزم المدعومون

| المنصة | مدير الحزم | التثبيت |
|--------|-----------|---------|
| Windows | winget | مضمن (يتطلب App Installer) |
| macOS | Homebrew | تلقائي |
| Linux | apt | مضمن (Ubuntu/Debian) |
| Linux | dnf | مضمن (Fedora/RHEL) |
| Linux | pacman | مضمن (Arch/Manjaro) |

## استكشاف الأخطاء وإصلاحها

### Windows

**خطأ "Execution Policy":**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

**"winget not found":**
- ثبّت App Installer من Microsoft Store
- أو شغّل `winget` في طرفية جديدة بعد التثبيت

**"PowerShell 5.1 required":**
- Windows 10+ يتضمن PowerShell 5.1 افتراضياً
- تحقق من الإصدار: `$PSVersionTable.PSVersion`

### macOS

**"brew not found":**
- السكريبت سيثبّت Homebrew تلقائياً
- أو يدوياً: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied":**
- شغّل مع前缀 `bash`: `bash quickstart.sh`

### Linux

**"apt not found":**
- السكريبت يكتشف تلقائياً `apt`، `dnf` أو `pacman`
- للتوزيعات غير المدعومة، استخدم `--cfg-path` مع أوامر مخصصة

## المساهمة

Issues و Pull Requests مرحب بها!

### إضافة برنامج جديد

1. عدّل `config/profiles.json`
2. أضف إدخال البرنامج في قسم `"software"`
3. أضف مفتاح البرنامج إلى مصفوفة `"includes"` للملف الشخصي
4. قدّم Pull Request

### إضافة ملف شخصي جديد

1. عدّل `config/profiles.json`
2. أضف الملف الشخصي الجديد في قسم `"profiles"`
3. قدّم Pull Request

## الترخيص

[MIT](LICENSE)
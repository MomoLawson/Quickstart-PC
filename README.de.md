# Quickstart-PC

> Ein-Klick-Computer-Einrichtung - Unterstützt Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**Andere Sprachen**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## Funktionen

- 🚀 **Ein-Klick-Installation** - Richten Sie Ihren neuen Computer mit einem Befehl ein
- 🎯 **Vorgefertigte Profile** - 5 kuratierte Profile für verschiedene Bedürfnisse
- 🌐 **Plattformübergreifend** - Unterstützt Windows / macOS / Linux
- ☁️ **Remote-Konfiguration** - Holen Sie die neueste Konfiguration aus der Cloud
- 📦 **Paketmanager** - Automatische Erkennung und Installation von Paketmanagern
- 🌍 **Mehrsprachig** - Manuelle Sprachauswahl, unterstützt mehrere Sprachen

## Schnellstart

### macOS / Linux (Empfohlen)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# Methode 1: Herunterladen und ausführen
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# Methode 2: Einzeiler
powershell -ExecutionPolicy Bypass -Command "[System.Text.Encoding]::UTF8.GetString((New-Object System.Net.WebClient).DownloadData('https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1'))|iex"
```

## Profile

| Profil | Beschreibung | Enthaltene Software |
|--------|-------------|---------------------|
| ⭐ Empfohlen | Ausgewogen, für die meisten Benutzer | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 KI-gesteuert | KI-CLI-Tools, intelligente IDEs | Cursor, Ollama, LM Studio |
| 📊 Büro-Suite | Dokumente, Tabellen, Zusammenarbeit | WPS, Obsidian, Notion |
| 💻 Entwickler | IDEs, Versionskontrolle, Runtimes | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 Medien | Audio-/Videoverarbeitung | VLC, OBS Studio |

## Projektstruktur

```
Quickstart-PC/
├── src/
│   ├── quickstart.sh       # Bash-Quellcode (hier entwickeln)
│   └── quickstart.ps1      # PowerShell-Quellcode (hier entwickeln)
├── dist/
│   ├── quickstart.sh       # Bash-Build-Artefakt (nicht direkt bearbeiten)
│   └── quickstart.ps1      # PowerShell-Build-Artefakt (nicht direkt bearbeiten)
├── scripts/
│   └── build.sh            # Build-Skript (injiziert Version)
├── config/
│   └── profiles.json       # Softwareprofile-Konfiguration (JSON)
├── VERSION                 - Single Source of Truth für Version
├── README.md               # Englische Dokumentation
└── README.de.md            # Deutsche Dokumentation
```

### Entwicklungsworkflow

```bash
# Quelldateien bearbeiten
nano src/quickstart.sh
nano src/quickstart.ps1

# Beide dist-Dateien erstellen
bash scripts/build.sh

# Lokal testen
bash dist/quickstart.sh --list-proamples
```

## Mehrsprachige Unterstützung

Manuelle Sprachauswahl mit Pfeiltasten-Navigation:

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

Verwenden Sie `--lang de`, `--lang en` oder andere Sprachcodes, um das Sprachauswahlmenü zu überspringen.

## Benutzerdefinierte Konfiguration

### Remote-Konfiguration (Standard)

Das Skript holt automatisch die Konfiguration von:
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### Benutzerdefinierte Remote-URL

```bash
quickstart.sh --cfg-url https://your-server.com/profiles.json
```

### Lokale Konfiguration

```bash
quickstart.sh --cfg-path /path/to/profiles.json
```

### JSON-Konfigurationsformat

```json
{
  "profiles": {
    "my_custom": {
      "name": "Mein Profil",
      "desc": "Benutdefinierte Softwarekombination",
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

## Befehlszeilenoptionen

| Option | Beschreibung |
|--------|---------------|
| `--lang LANG` | Sprache festlegen |
| `--dev` | Entwicklermodus: Auswahl anzeigen ohne zu installieren |
| `--dry-run` | Simulation: Prozess anzeigen ohne zu installieren |
| `--yes` / `-y` | Alle Prompts automatisch bestätigen |
| `--verbose` | Detaillierte Debug-Infos anzeigen |
| `--log-file FILE` | Logs in Datei schreiben |
| `--export-plan FILE` | Installationsplan exportieren |
| `--custom` | Benutzerdefinierte Software-Auswahl (manuelle Auswahl) |
| `--retry-failed` | Zuerst fehlgeschlagene Pakete erneut versuchen |
| `--list-profiles` | Alle verfügbaren Profile auflisten |
| `--show-profile KEY` | Profildetails anzeigen |
| `--skip SW` | Software überspringen (wiederholbar) |
| `--only SW` | Nur angegebene Software installieren (wiederholbar) |
| `--fail-fast` | Bei erstem Fehler stoppen |
| `--profile NAME` | Profil direkt auswählen (Menü überspringen) |
| `--non-interactive` | Nicht-interaktiver Modus (keine TUI/Prompts) |
| `--cfg-path PATH` | Lokale profiles.json verwenden |
| `--cfg-url URL` | Remote profiles.json URL verwenden |
| `--version` / `-v` | Versionsinfo anzeigen |
| `--help` | Hilfe anzeigen |

## Unterstützte Paketmanager

| Plattform | Paketmanager | Installation |
|-----------|--------------|---------------|
| Windows | winget | Integriert (erfordert App Installer) |
| macOS | Homebrew | Auto-Installation |
| Linux | apt | Integriert (Ubuntu/Debian) |
| Linux | dnf | Integriert (Fedora/RHEL) |
| Linux | pacman | Integriert (Arch/Manjaro) |

## Fehlerbehebung

### Windows

**"Execution Policy"-Fehler:**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

**"winget not found":**
- App Installer aus dem Microsoft Store installieren
- Oder `winget` in einem neuen Terminal nach der Installation ausführen

**"PowerShell 5.1 required":**
- Windows 10+ enthält standardmäßig PowerShell 5.1
- Version überprüfen: `$PSVersionTable.PSVersion`

### macOS

**"brew not found":**
- Das Skript installiert Homebrew automatisch
- Oder manuell: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied":**
- Mit `bash`-Präfix ausführen: `bash quickstart.sh`

### Linux

**"apt not found":**
- Das Skript erkennt automatisch `apt`, `dnf` oder `pacman`
- Für nicht unterstützte Distributionen `--cfg-path` mit benutzerdefinierten Befehlen verwenden

## Mitwirken

Issues und Pull Requests sind willkommen!

### Neue Software hinzufügen

1. `config/profiles.json` bearbeiten
2. Softwareeintrag im Abschnitt `"software"` hinzufügen
3. Softwareschlüssel zum `"includes"`-Array des Profils hinzufügen
4. PR einreichen

### Neue Profile hinzufügen

1. `config/profiles.json` bearbeiten
2. Neues Profil im Abschnitt `"profiles"` hinzufügen
3. PR einreichen

## Lizenz

[MIT](LICENSE)
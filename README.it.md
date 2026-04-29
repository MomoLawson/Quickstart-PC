# Quickstart-PC

> Configurazione PC con un clic - Supporta Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**Altre lingue**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## Caratteristiche

- 🚀 **Installazione con un clic** - Configura il tuo nuovo computer con un comando
- 🎯 **Profili predefiniti** - 5 profili curati per diverse esigenze
- 🌐 **Multi-piattaforma** - Supporta Windows / macOS / Linux
- ☁️ **Configurazione remota** - Recupera l'ultima configurazione dal cloud
- 📦 **Gestore pacchetti** - Rileva e installa automaticamente i gestori di pacchetti
- 🌍 **Multilingua** - Selezione manuale della lingua, diverse lingue supportate

## Avvio Rapido

### macOS / Linux (Consigliato)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# Metodo 1: Scarica ed esegui
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# Metodo 2: Riga singola
powershell -ExecutionPolicy Bypass -Command "iwr https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1 | iex"
```

## Profili

| Profilo | Descrizione | Software Inclusi |
|---------|-------------|-------------------|
| ⭐ Consigliato | Bilanciato, adatto alla maggior parte degli utenti | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 IA | Strumenti CLI IA, IDE intelligenti | Cursor, Ollama, LM Studio |
| 📊 Ufficio | Documenti, fogli di calcolo, collaborazione | WPS, Obsidian, Notion |
| 💻 Sviluppatore | IDE, controllo versione, runtime | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 Media | Strumenti di elaborazione audio/video | VLC, OBS Studio |

## Struttura del Progetto

```
Quickstart-PC/
├── src/
│   ├── quickstart.sh       # Codice sorgente Bash (sviluppare qui)
│   └── quickstart.ps1      # Codice sorgente PowerShell (sviluppare qui)
├── dist/
│   ├── quickstart.sh       # Artefatto Bash compilato (non modificare direttamente)
│   └── quickstart.ps1      # Artefatto PowerShell compilato (non modificare direttamente)
├── scripts/
│   └── build.sh            # Script di build (inietta la versione)
├── config/
│   └── profiles.json       # Configurazione profili software (JSON)
├── VERSION                 # Fonte unica di verità per la versione
├── README.md               # Documentazione in inglese
└── README.it.md            # Documentazione in italiano
```

### Flusso di Sviluppo

```bash
# Modifica i file sorgente
nano src/quickstart.sh
nano src/quickstart.ps1

# Compila entrambi i file dist
bash scripts/build.sh

# Testa localmente
bash dist/quickstart.sh --list-profiles
```

## Supporto Multilingua

Selezione manuale della lingua con navigazione a frecce:

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

Usa `--lang it`, `--lang en` o altri codici lingua per saltare il menu di selezione lingua.

## Configurazione Personalizzata

### Configurazione Remota (Predefinita)

Lo script recupera automaticamente la configurazione da:
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### URL Remota Personalizzata

```bash
quickstart.sh --cfg-url https://tuo-server.com/profiles.json
```

### Configurazione Locale

```bash
quickstart.sh --cfg-path /percorso/a/profiles.json
```

### Formato Configurazione JSON

```json
{
  "profiles": {
    "my_custom": {
      "name": "Il mio profilo",
      "desc": "Combinazione software personalizzata",
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

## Opzioni da Riga di Comando

| Opzione | Descrizione |
|---------|-------------|
| `--lang LANG` | Imposta lingua |
| `--dev` | Modalità sviluppo: mostra selezioni senza installare |
| `--dry-run` | Installazione simulata: mostra processo senza installare |
| `--yes` / `-y` | Conferma automaticamente tutti i prompt |
| `--verbose` | Mostra info debug dettagliate |
| `--log-file FILE` | Scrivi log su file |
| `--export-plan FILE` | Esporta piano di installazione |
| `--custom` | Modalità selezione software personalizzata (manuale) |
| `--retry-failed` | Riprova pacchetti precedentemente falliti |
| `--list-profiles` | Elenca tutti i profili disponibili |
| `--show-profile KEY` | Mostra dettagli profilo |
| `--skip SW` | Salta software specificato (ripetibile) |
| `--only SW` | Installa solo software specificato (ripetibile) |
| `--fail-fast` | Ferma al primo errore |
| `--profile NAME` | Seleziona profilo direttamente (salta menu) |
| `--non-interactive` | Modalità non interattiva (no TUI/prompt) |
| `--cfg-path PATH` | Usa profiles.json locale |
| `--cfg-url URL` | Usa URL profiles.json remota |
| `--version` / `-v` | Mostra informazioni versione |
| `--help` | Mostra aiuto |

## Gestori Pacchetti Supportati

| Piattaforma | Gestore Pacchetti | Installazione |
|-------------|-------------------|---------------|
| Windows | winget | Integrato (richiede App Installer) |
| macOS | Homebrew | Auto-installazione |
| Linux | apt | Integrato (Ubuntu/Debian) |
| Linux | dnf | Integrato (Fedora/RHEL) |
| Linux | pacman | Integrato (Arch/Manjaro) |

## Risoluzione Problemi

### Windows

**Errore "Execution Policy":**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

**"winget not found":**
- Installa App Installer da Microsoft Store
- Oppure esegui `winget` in un nuovo terminale dopo l'installazione

**"PowerShell 5.1 required":**
- Windows 10+ include PowerShell 5.1 per impostazione predefinita
- Verifica versione: `$PSVersionTable.PSVersion`

### macOS

**"brew not found":**
- Lo script installerà automaticamente Homebrew
- Oppure manualmente: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied":**
- Esegui con prefisso `bash`: `bash quickstart.sh`

### Linux

**"apt not found":**
- Lo script rileva automaticamente `apt`, `dnf` o `pacman`
- Per distribuzioni non supportate, usa `--cfg-path` con comandi personalizzati

## Contribuzione

Issue e Pull Request sono benvenute!

### Aggiungere Nuovo Software

1. Modifica `config/profiles.json`
2. Aggiungi la voce software nella sezione `"software"`
3. Aggiungi la chiave software all'array `"includes"` del profilo
4. Invia una Pull Request

### Aggiungere Nuovo Profilo

1. Modifica `config/profiles.json`
2. Aggiungi il nuovo profilo nella sezione `"profiles"`
3. Invia una Pull Request

## Licenza

[MIT](LICENSE)
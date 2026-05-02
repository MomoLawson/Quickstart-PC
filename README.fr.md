# Quickstart-PC

> Configuration PC en un clic - Supporte Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**Autres langues**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## Fonctionnalités

- 🚀 **Installation en un clic** - Configurez votre nouvel ordinateur avec une seule commande
- 🎯 **Profils prédéfinis** - 5 profils adaptés à différents besoins
- 🌐 **Multi-plateforme** - Supporte Windows / macOS / Linux
- ☁️ **Configuration distante** - Récupérez la dernière configuration depuis le cloud
- 📦 **Gestionnaire de paquets** - Détection et installation automatiques des gestionnaires de paquets
- 🌍 **Multilingue** - Sélection manuelle de la langue, plusieurs langues supportées

## Démarrage rapide

### macOS / Linux (Recommandé)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# Méthode 1: Télécharger et exécuter
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# Méthode 2: Ligne unique
powershell -ExecutionPolicy Bypass -Command "$bytes = (New-Object System.Net.WebClient).DownloadData('https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1'); iex ([System.Text.Encoding]::UTF8.GetString($bytes))"
```

## Profils

| Profil | Description | Logiciels inclus |
|--------|-------------|-------------------|
| ⭐ Recommandé | Équilibré, adapté à la plupart des utilisateurs | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 IA | Outils CLI IA, IDEs intelligents | Cursor, Ollama, LM Studio |
| 📊 Bureau | Documents, tableurs, collaboration | WPS, Obsidian, Notion |
| 💻 Développeur | IDEs, contrôle de versions, runtimes | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 Média | Outils de traitement audio/vidéo | VLC, OBS Studio |

## Structure du projet

```
Quickstart-PC/
├── src/
│   ├── quickstart.sh       # Code source Bash (développer ici)
│   └── quickstart.ps1      # Code source PowerShell (développer ici)
├── dist/
│   ├── quickstart.sh       # Artifact Bash compilé (ne pas éditer directement)
│   └── quickstart.ps1      # Artifact PowerShell compilé (ne pas éditer directement)
├── scripts/
│   └── build.sh            # Script de build (injecte la version)
├── config/
│   └── profiles.json       # Configuration des profils logiciels (JSON)
├── VERSION                 # Source unique de vérité pour la version
├── README.md               # Documentation anglaise
└── README.fr.md            # Documentation française
```

### Flux de développement

```bash
# Éditer les fichiers sources
nano src/quickstart.sh
nano src/quickstart.ps1

# Compiler les deux fichiers dist
bash scripts/build.sh

# Tester localement
bash dist/quickstart.sh --list-profiles
```

## Support multilingue

Sélection manuelle de la langue avec navigation par touches fléchées :

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

Utilisez `--lang fr`, `--lang en` ou d'autres codes de langue pour passer le menu de sélection de langue.

## Configuration personnalisée

### Configuration distante (Par défaut)

Le script récupère automatiquement la configuration depuis :
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### URL distante personnalisée

```bash
quickstart.sh --cfg-url https://votre-serveur.com/profiles.json
```

### Configuration locale

```bash
quickstart.sh --cfg-path /chemin/vers/profiles.json
```

### Format de configuration JSON

```json
{
  "profiles": {
    "my_custom": {
      "name": "Mon Profil",
      "desc": "Combinaison de logiciels personnalisée",
      "icon": "🎮",
      "includes": ["chrome", "vscode"]
    }
  },
  "software": {
    "chrome": {
      "name": "Chrome",
      "desc": "Navigateur",
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

## Options de ligne de commande

| Option | Description |
|--------|-------------|
| `--lang LANG` | Définir la langue |
| `--dev` | Mode développement : afficher les sélections sans installer |
| `--dry-run` | Installation simulée : afficher le processus sans installer |
| `--yes` / `-y` | Confirmer automatiquement toutes les invites |
| `--verbose` | Afficher les infos de débogage détaillées |
| `--log-file FILE` | Écrire les logs dans un fichier |
| `--export-plan FILE` | Exporter le plan d'installation |
| `--custom` | Mode de sélection de logiciels personnalisé (manuel) |
| `--retry-failed` | Réessayer les paquets précédemment échoués |
| `--list-profiles` | Lister tous les profils disponibles |
| `--show-profile KEY` | Afficher les détails du profil |
| `--skip SW` | Ignorer le logiciel spécifié (répétable) |
| `--only SW` | Installer uniquement le logiciel spécifié (répétable) |
| `--fail-fast` | Arrêter à la première erreur |
| `--profile NAME` | Sélectionner le profil directement (passer le menu) |
| `--non-interactive` | Mode non interactif (pas de TUI/prompts) |
| `--cfg-path PATH` | Utiliser profiles.json local |
| `--cfg-url URL` | Utiliser URL profiles.json distante |
| `--version` / `-v` | Afficher les infos de version |
| `--help` | Afficher l'aide |

## Gestionnaires de paquets supportés

| Plateforme | Gestionnaire de paquets | Installation |
|------------|------------------------|--------------|
| Windows | winget | Intégré (requiert App Installer) |
| macOS | Homebrew | Auto-installation |
| Linux | apt | Intégré (Ubuntu/Debian) |
| Linux | dnf | Intégré (Fedora/RHEL) |
| Linux | pacman | Intégré (Arch/Manjaro) |

## Dépannage

### Windows

**Erreur "Execution Policy" :**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

**"winget not found" :**
- Installer App Installer depuis le Microsoft Store
- Ou exécuter `winget` dans un nouveau terminal après l'installation

**"PowerShell 5.1 required" :**
- Windows 10+ inclut PowerShell 5.1 par défaut
- Vérifier la version : `$PSVersionTable.PSVersion`

### macOS

**"brew not found" :**
- Le script installera automatiquement Homebrew
- Ou manuellement : `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied" :**
- Exécuter avec le préfixe `bash` : `bash quickstart.sh`

### Linux

**"apt not found" :**
- Le script détecte automatiquement `apt`, `dnf` ou `pacman`
- Pour les distributions non supportées, utiliser `--cfg-path` avec des commandes personnalisées

## Contribution

Les Issues et Pull Requests sont les bienvenues !

### Ajouter un nouveau logiciel

1. Éditer `config/profiles.json`
2. Ajouter l'entrée logicielle dans la section `"software"`
3. Ajouter la clé logicielle au tableau `"includes"` du profil
4. Soumettre une PR

### Ajouter un nouveau profil

1. Éditer `config/profiles.json`
2. Ajouter le nouveau profil dans la section `"profiles"`
3. Soumettre une PR

## Licence

[MIT](LICENSE)
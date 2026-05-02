# Quickstart-PC

> Configuração de PC com um clique - Suporta Windows / macOS / Linux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

**Outros Idiomas**: [English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [العربية](README.ar.md) | [Português](README.pt.md) | [Italiano](README.it.md)

## Funcionalidades

- 🚀 **Instalação com um clique** - Configure seu novo computador com um comando
- 🎯 **Perfis pré-definidos** - 5 perfis selecionados para diferentes necessidades
- 🌐 **Multiplataforma** - Suporta Windows / macOS / Linux
- ☁️ **Configuração remota** - Busque a configuração mais recente da nuvem
- 📦 **Gerenciador de pacotes** - Detecta e instala gerenciadores de pacotes automaticamente
- 🌍 **Multilíngue** - Seleção manual de idioma, vários idiomas suportados

## Início Rápido

### macOS / Linux (Recomendado)

```bash
bash <(curl -fsSL https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.sh)
```

### Windows

```powershell
# Método 1: Baixar e executar
Invoke-WebRequest -Uri "https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1" -OutFile "quickstart.ps1"
powershell -ExecutionPolicy Bypass -File quickstart.ps1

# Método 2: Uma linha
powershell -ExecutionPolicy Bypass -Command "$bytes = (New-Object System.Net.WebClient).DownloadData('https://github.com/MomoLawson/Quickstart-PC/releases/latest/download/quickstart.ps1'); iex ([System.Text.Encoding]::UTF8.GetString($bytes))"
```

## Perfis

| Perfil | Descrição | Software Incluído |
|--------|-----------|-------------------|
| ⭐ Recomendado | Equilibrado, adequado para a maioria dos usuários | Chrome, Edge, VS Code, Git, Node.js, Python, WPS, VLC |
| 🤖 IA | Ferramentas CLI de IA, IDEs inteligentes | Cursor, Ollama, LM Studio |
| 📊 Escritório | Documentos, planilhas, colaboração | WPS, Obsidian, Notion |
| 💻 Desenvolvedor | IDEs, controle de versão, runtimes | VS Code, IntelliJ, Git, Node.js, Python, Go, Docker |
| 🎬 Mídia | Ferramentas de processamento de áudio/vídeo | VLC, OBS Studio |

## Estrutura do Projeto

```
Quickstart-PC/
├── src/
│   ├── quickstart.sh       # Código fonte Bash (desenvolver aqui)
│   └── quickstart.ps1      # Código fonte PowerShell (desenvolver aqui)
├── dist/
│   ├── quickstart.sh       # Artefato Bash compilado (não editar diretamente)
│   └── quickstart.ps1      # Artefato PowerShell compilado (não editar diretamente)
├── scripts/
│   └── build.sh            # Script de build (injeta versão)
├── config/
│   └── profiles.json       # Configuração de perfis de software (JSON)
├── VERSION                 # Fonte única de verdade para versão
├── README.md               # Documentação em inglês
└── README.pt.md            # Documentação em português
```

### Fluxo de Desenvolvimento

```bash
# Editar arquivos fontes
nano src/quickstart.sh
nano src/quickstart.ps1

# Compilar ambos os arquivos dist
bash scripts/build.sh

# Testar localmente
bash dist/quickstart.sh --list-profiles
```

## Suporte Multilíngue

Seleção manual de idioma com navegação por teclas de seta:

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

Use `--lang pt`, `--lang en` ou outros códigos de idioma para pular o menu de seleção de idioma.

## Configuração Personalizada

### Configuração Remota (Padrão)

O script busca automaticamente a configuração de:
```
https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json
```

### URL Remota Personalizada

```bash
quickstart.sh --cfg-url https://seu-servidor.com/profiles.json
```

### Configuração Local

```bash
quickstart.sh --cfg-path /caminho/para/profiles.json
```

### Formato de Configuração JSON

```json
{
  "profiles": {
    "my_custom": {
      "name": "Meu Perfil",
      "desc": "Combinação de software personalizada",
      "icon": "🎮",
      "includes": ["chrome", "vscode"]
    }
  },
  "software": {
    "chrome": {
      "name": "Chrome",
      "desc": "Navegador",
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

## Opções de Linha de Comando

| Opção | Descrição |
|-------|-----------|
| `--lang LANG` | Definir idioma |
| `--dev` | Modo desenvolvimento: mostrar escolhas sem instalar |
| `--dry-run` | Instalação simulada: mostrar processo sem instalar |
| `--yes` / `-y` | Confirmar automaticamente todos os prompts |
| `--verbose` | Mostrar informações de debug detalhadas |
| `--log-file FILE` | Escrever logs em arquivo |
| `--export-plan FILE` | Exportar plano de instalação |
| `--custom` | Modo de seleção de software personalizado (manual) |
| `--retry-failed` | Tentar pacotes que falharam anteriormente |
| `--list-profiles` | Listar todos os perfis disponíveis |
| `--show-profile KEY` | Mostrar detalhes do perfil |
| `--skip SW` | Pular software especificado (repetível) |
| `--only SW` | Instalar apenas o software especificado (repetível) |
| `--fail-fast` | Parar no primeiro erro |
| `--profile NAME` | Selecionar perfil diretamente (pular menu) |
| `--non-interactive` | Modo não interativo (sem TUI/prompts) |
| `--cfg-path PATH` | Usar profiles.json local |
| `--cfg-url URL` | Usar URL profiles.json remota |
| `--version` / `-v` | Mostrar informações da versão |
| `--help` | Mostrar ajuda |

## Gerenciadores de Pacotes Suportados

| Plataforma | Gerenciador de Pacotes | Instalação |
|------------|----------------------|------------|
| Windows | winget | Integrado (requer App Installer) |
| macOS | Homebrew | Auto-instalação |
| Linux | apt | Integrado (Ubuntu/Debian) |
| Linux | dnf | Integrado (Fedora/RHEL) |
| Linux | pacman | Integrado (Arch/Manjaro) |

## Solução de Problemas

### Windows

**Erro "Execution Policy":**
```powershell
powershell -ExecutionPolicy Bypass -File quickstart.ps1
```

**"winget not found":**
- Instale o App Installer da Microsoft Store
- Ou execute `winget` em um novo terminal após a instalação

**"PowerShell 5.1 required":**
- Windows 10+ inclui PowerShell 5.1 por padrão
- Verifique a versão: `$PSVersionTable.PSVersion`

### macOS

**"brew not found":**
- O script instalará o Homebrew automaticamente
- Ou manualmente: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**"Permission denied":**
- Execute com o prefixo `bash`: `bash quickstart.sh`

### Linux

**"apt not found":**
- O script detecta automaticamente `apt`, `dnf` ou `pacman`
- Para distribuições não suportadas, use `--cfg-path` com comandos personalizados

## Contribuição

Issues e Pull Requests são bem-vindos!

### Adicionar Novo Software

1. Edite `config/profiles.json`
2. Adicione a entrada de software na seção `"software"`
3. Adicione a chave do software ao array `"includes"` do perfil
4. Envie um Pull Request

### Adicionar Novo Perfil

1. Edite `config/profiles.json`
2. Adicione o novo perfil na seção `"profiles"`
3. Envie um Pull Request

## Licença

[MIT](LICENSE)
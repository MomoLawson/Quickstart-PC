# shellcheck shell=bash
# Quickstart-PC Language Pack: pt (Português)

HELP_TITLE="Quickstart-PC - Configuração de PC com um clique"
HELP_USAGE="Uso: quickstart.sh [OPÇÕES]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
Opções:
  --lang LANG        Definir idioma (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  Pasta de scripts de idioma local
  --cfg-path PATH    Usar arquivo profiles.json local
  --cfg-url URL      Usar URL profiles.json remoto
  --dev              Modo desenvolvedor: mostrar seleções sem instalar
  --dry-run          Modo visualização: mostrar processo sem instalar
  doctor              Executar diagnósticos QC Doctor
  doctor --fix        Reparar automaticamente dependências ausentes
  --yes, -y          Confirmar automaticamente todos os prompts
  --verbose              Mostrar informações de depuração detalhadas
  --log-file FILE          Escrever logs em arquivo
  --export-plan FILE       Exportar plano de instalação
  --retry-failed           Tentar novamente pacotes que falharam anteriormente
  --list-software    Listar todos os softwares disponíveis
  --show-software ID Mostrar detalhes do software
  --search KEYWORD   Pesquisar software
  --validate         Validar arquivo de configuração
  --report-json FILE Exportar relatório de instalação em formato JSON
  --report-txt FILE  Exportar relatório de instalação em formato TXT
  --list-profiles    Listar todos os perfis disponíveis
  --show-profile KEY Mostrar detalhes do perfil
  --skip SW          Pular software especificado (repetível)
  --only SW          Instalar apenas software especificado (repetível)
  --fail-fast        Parar no primeiro erro
  --profile NAME     Selecionar perfil diretamente (pular menu)
  --non-interactive  Modo não interativo (sem TUI/prompts)
  --resume                  Retomar instalação interrompida
  --no-resume               Não retomar instalação interrompida
  --update             Atualizar script para a versão mais recente
  --check-update            Verificar atualizações sem instalar
  --allow-hooks             Ativar execução de scripts hook
  --version, -v             Mostrar informações da versão
  --help             Mostrar esta mensagem de ajuda
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="Configuração rápida para novos computadores"
LANG_DETECTING_SYSTEM="Detectando ambiente do sistema..."
LANG_SYSTEM_INFO="Sistema"
LANG_PACKAGE_MANAGER="Gerenciador de pacotes"
LANG_UNSUPPORTED_OS="Sistema operacional não suportado"
LANG_USING_REMOTE_CONFIG="Usando configuração remota"
LANG_USING_CUSTOM_CONFIG="Usando configuração local"
LANG_USING_DEFAULT_CONFIG="Usando configuração padrão"
LANG_CONFIG_NOT_FOUND="Arquivo de configuração não encontrado"
LANG_CONFIG_INVALID="Formato de arquivo de configuração inválido"
LANG_SELECT_PROFILES="Selecionar Perfis de Instalação"
LANG_SELECT_SOFTWARE="Selecionar Software para Instalar"
LANG_NAVIGATE="↑↓ Mover | ENTER Confirmar"
LANG_NAVIGATE_MULTI="↑↓ Mover | ESPAÇO Selecionar | ENTER Confirmar"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="Selecionar Tudo"
LANG_BACK_TO_PROFILES="Voltar à seleção de perfis"
LANG_NO_PROFILE_SELECTED="Nenhum perfil selecionado"
LANG_NO_SOFTWARE_SELECTED="Nenhum software selecionado"
LANG_CONFIRM_INSTALL="Confirmar instalação? [Y/n]"
LANG_CANCELLED="Cancelado"
LANG_START_INSTALLING="Iniciando instalação de software"
LANG_INSTALLING="Instalando"
LANG_INSTALL_SUCCESS="instalado com sucesso"
LANG_INSTALL_FAILED="falha na instalação"
LANG_PLATFORM_NOT_SUPPORTED="Plataforma não suportada"
LANG_INSTALLATION_COMPLETE="Instalação Concluída"
LANG_TOTAL_INSTALLED="Total instalado"
LANG_DEV_MODE="Modo desenvolvedor: mostrar software selecionado sem instalar"
LANG_DRY_RUN_MODE="Modo visualização: mostrar processo sem instalar"
LANG_DRY_RUN_INSTALLING="Simulando instalação"
LANG_JQ_DETECTED="jq detectado, usando jq"
LANG_JQ_NOT_FOUND="jq não encontrado, instalando..."
LANG_JQ_INSTALLED="jq instalado com sucesso"
LANG_JQ_INSTALL_FAILED="Falha na instalação do jq, tentando parser alternativo..."
LANG_USING_PYTHON3="Usando python3 como parser alternativo"
LANG_NO_JSON_PARSER="Nenhum parser JSON disponível (jq/python3)"
LANG_CHECKING_INSTALLATION="Verificando status da instalação..."
LANG_SKIPPING_INSTALLED="Já instalado, pulando"
LANG_ALL_INSTALLED="Todo software já instalado, nada a fazer"
LANG_ASK_CONTINUE="Instalação concluída. Continuar instalando outros perfis?"
LANG_CONTINUE="Continuar Instalação"
LANG_EXIT="Sair"
LANG_TITLE_SELECT_PROFILE="Selecionar Perfil"
LANG_TITLE_SELECT_SOFTWARE="Selecionar Software"
LANG_TITLE_INSTALLING="Instalando"
LANG_TITLE_ASK_CONTINUE="Continuar Instalação?"
LANG_LANG_PROMPT="Selecione o idioma"
LANG_LANG_MENU_ENTER="Confirmar"
LANG_LANG_MENU_SPACE="Selecionar"
LANG_NONINTERACTIVE_ERROR="Modo não interativo requer parâmetro --profile"
LANG_PROFILE_NOT_FOUND="Perfil '$PROFILE_KEY' não encontrado"
LANG_NPM_NOT_FOUND="npm não encontrado, instalando..."
LANG_WINGET_NOT_FOUND="winget não encontrado, não é possível instalar npm automaticamente"
LANG_NPM_AUTO="npm"
LANG_INSTALL_FAILED_LIST="Os seguintes softwares falharam na instalação"
LANG_PROGRESS_INSTALLED="instalados"
LANG_PROGRESS_TO_INSTALL="a instalar"
LANG_TIME_SECONDS="s"
LANG_TIME_TOTAL="Tempo total"
LANG_RETRY_PROMPT="Tentar novamente? [Y/n]"
LANG_RETRYING="Tentando novamente"
LANG_ERROR_DETAIL="Detalhe do erro"
LANG_CUSTOM_TITLE="Seleção personalizada"
LANG_CUSTOM_SPACE_TOGGLE="Espaço: alternar"
LANG_CUSTOM_ENTER_CONFIRM="Enter: confirmar"
LANG_CUSTOM_A_SELECT_ALL="A: selecionar/deselecionar tudo"
LANG_CUSTOM_SELECTED="Selecionado %d/%d"
LANG_DISK_SPACE_LOW="Espaço em disco insuficiente: %sGB disponível, pelo menos %sGB recomendado"
LANG_DISK_SPACE_WARNING="⚠ Espaço em disco baixo, a instalação pode falhar"
LANG_DISK_CHECKING="Verificando espaço em disco..."
LANG_NETWORK_TIMEOUT="Tempo limite de conexão de rede esgotado, verifique suas configurações de rede"
LANG_NETWORK_ERROR="Erro de rede: %s"
LANG_CHECK_NETWORK="Sugestão: Verifique a conexão de rede ou configure um proxy"
LANG_PERMISSION_DENIED="Permissão negada: %s"
LANG_PERMISSION_SUGGESTION="Sugestão: Execute com sudo ou contate o administrador"
LANG_NEED_SUDO="Esta operação requer privilégios de administrador"
LANG_NEED_ADMIN="Por favor, execute como Administrador"
LANG_RESUME_FOUND="Instalação incompleta encontrada. Continuar? [Y/n]"
LANG_RESUMING="Retomando do último ponto de verificação..."
LANG_CHECKPOINT_SAVED="Progresso da instalação salvo"
LANG_INSTALL_COMPLETE_STATE="Instalação concluída, limpando arquivos temporários"
LANG_UPDATE_CHECKING="Verificando atualizações..."
LANG_UPDATE_AVAILABLE="Nova versão disponível: %s (atual: %s)"
LANG_UPDATE_LATEST="Já está na versão mais recente"
LANG_UPDATE_DOWNLOADING="Baixando atualização..."
LANG_UPDATE_SUCCESS="Atualização bem-sucedida! Por favor, reinicie o script"
LANG_UPDATE_FAILED="Falha na atualização: %s"
LANG_UPDATE_PROMPT="Atualizar para a nova versão? [Y/n]"
LANG_UPDATE_CTRL_U="Nova versão %s disponível. Pressione Ctrl+U para atualizar"
LANG_HOOK_RUNNING="Executando hook: %s"
LANG_HOOK_SUCCESS="Hook concluído"
LANG_HOOK_FAILED="Falha no hook: %s"
LANG_HOOKS_DISABLED="Hooks desativados, use --allow-hooks para ativar"
LANG_HOOKS_ENABLED="Hooks ativados"
LANG_BATCH_INSTALLING="Instalação em lote de %d pacotes..."
LANG_BATCH_SUCCESS="Instalação em lote concluída: %d/%d sucedidos"
LANG_BATCH_FAILED="Instalação em lote parcialmente falhou, voltando à instalação individual..."
LANG_BYE="Quickstart-PC foi encerrado. Adeus!"


LANG_CONFIG_VERIFY_FAILED="Falha na verificação da configuração"
LANG_CONFIG_CHECKSUM_NOT_FOUND="Arquivo de checksum não encontrado"
LANG_CONFIG_CHECKSUM_MISMATCH="Checksum incompatível"
LANG_CONFIG_VERIFY_SUCCESS="Verificação da configuração bem-sucedida"

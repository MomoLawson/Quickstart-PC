# shellcheck shell=bash
# Quickstart-PC Language Pack: it (Italiano)

HELP_TITLE="Quickstart-PC - Configurazione PC con un clic"
HELP_USAGE="Utilizzo: quickstart.sh [OPZIONI]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
Opzioni:
  --lang LANG        Imposta lingua (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  Cartella script lingua locale
  --cfg-path PATH    Usa file profiles.json locale
  --cfg-url URL      Usa URL profiles.json remoto
  --dev              Modalità sviluppatore: mostra selezioni senza installare
  --dry-run          Modalità anteprima: mostra processo senza installare
  --doctor           Esegui diagnosi ambiente QC Doctor
  --yes, -y          Conferma automaticamente tutti i prompt
  --verbose, -v      Mostra informazioni di debug dettagliate
  --log-file FILE    Scrivi log su file
  --export-plan FILE Esporta piano di installazione
  --custom           Modalità selezione software personalizzata
  --retry-failed     Riprova pacchetti precedentemente falliti
  --list-software    Elenca tutti i software disponibili
  --show-software ID Mostra dettagli del software
  --search KEYWORD   Cerca software
  --validate         Convalida file di configurazione
  --report-json FILE Esporta rapporto installazione in formato JSON
  --report-txt FILE  Esporta rapporto installazione in formato TXT
  --list-profiles    Elenca tutti i profili disponibili
  --show-profile KEY Mostra dettagli del profilo
  --skip SW          Salta software specificato (ripetibile)
  --only SW          Installa solo software specificato (ripetibile)
  --fail-fast        Ferma al primo errore
  --profile NAME     Seleziona profilo direttamente (salta menu)
  --non-interactive  Modalità non interattiva (senza TUI/prompt)
  --help             Mostra questo messaggio di aiuto
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="Configurazione rapida per nuovi computer"
LANG_DETECTING_SYSTEM="Rilevamento ambiente di sistema..."
LANG_SYSTEM_INFO="Sistema"
LANG_PACKAGE_MANAGER="Gestore pacchetti"
LANG_UNSUPPORTED_OS="Sistema operativo non supportato"
LANG_USING_REMOTE_CONFIG="Utilizzo configurazione remota"
LANG_USING_CUSTOM_CONFIG="Utilizzo configurazione locale"
LANG_USING_DEFAULT_CONFIG="Utilizzo configurazione predefinita"
LANG_CONFIG_NOT_FOUND="File di configurazione non trovato"
LANG_CONFIG_INVALID="Formato file di configurazione non valido"
LANG_SELECT_PROFILES="Seleziona Profili di Installazione"
LANG_SELECT_SOFTWARE="Seleziona Software da Installare"
LANG_NAVIGATE="↑↓ Sposta | INVIO Conferma"
LANG_NAVIGATE_MULTI="↑↓ Sposta | SPAZIO Seleziona | INVIO Conferma"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="Seleziona Tutto"
LANG_BACK_TO_PROFILES="Torna alla selezione profili"
LANG_NO_PROFILE_SELECTED="Nessun profilo selezionato"
LANG_NO_SOFTWARE_SELECTED="Nessun software selezionato"
LANG_CONFIRM_INSTALL="Confermare installazione? [Y/n]"
LANG_CANCELLED="Annullato"
LANG_START_INSTALLING="Avvio installazione software"
LANG_INSTALLING="Installazione"
LANG_INSTALL_SUCCESS="installato con successo"
LANG_INSTALL_FAILED="installazione fallita"
LANG_PLATFORM_NOT_SUPPORTED="Piattaforma non supportata"
LANG_INSTALLATION_COMPLETE="Installazione Completata"
LANG_TOTAL_INSTALLED="Totale installati"
LANG_DEV_MODE="Modalità sviluppatore: mostra software selezionato senza installare"
LANG_DRY_RUN_MODE="Modalità anteprima: mostra processo senza installare"
LANG_DRY_RUN_INSTALLING="Simulazione in corso"
LANG_JQ_DETECTED="jq rilevato, utilizzo jq"
LANG_JQ_NOT_FOUND="jq non trovato, installazione..."
LANG_JQ_INSTALLED="jq installato con successo"
LANG_JQ_INSTALL_FAILED="Installazione di jq fallita, provo parser alternativo..."
LANG_USING_PYTHON3="Utilizzo python3 come parser alternativo"
LANG_NO_JSON_PARSER="Nessun parser JSON disponibile (jq/python3)"
LANG_CHECKING_INSTALLATION="Verifica stato installazione..."
LANG_SKIPPING_INSTALLED="Già installato, salto"
LANG_ALL_INSTALLED="Tutto il software già installato, nulla da fare"
LANG_ASK_CONTINUE="Installazione completata. Continuare installazione di altri profili?"
LANG_CONTINUE="Continua Installazione"
LANG_EXIT="Esci"
LANG_TITLE_SELECT_PROFILE="Seleziona Profilo"
LANG_TITLE_SELECT_SOFTWARE="Seleziona Software"
LANG_TITLE_INSTALLING="Installazione in corso"
LANG_TITLE_ASK_CONTINUE="Continuare Installazione?"
LANG_LANG_PROMPT="Seleziona lingua"
LANG_LANG_MENU_ENTER="Conferma"
LANG_LANG_MENU_SPACE="Seleziona"
LANG_NONINTERACTIVE_ERROR="La modalità non interattiva richiede il parametro --profile"
LANG_PROFILE_NOT_FOUND="Profilo '$PROFILE_KEY' non trovato"
LANG_NPM_NOT_FOUND="npm non trovato, installazione..."
LANG_WINGET_NOT_FOUND="winget non trovato, impossibile installare npm automaticamente"
LANG_NPM_AUTO="npm"
LANG_INSTALL_FAILED_LIST="I seguenti software non sono stati installati"
LANG_PROGRESS_INSTALLED="installati"
LANG_PROGRESS_TO_INSTALL="da installare"
LANG_TIME_SECONDS="s"
LANG_TIME_TOTAL="Tempo totale"
LANG_RETRY_PROMPT="Riprovare? [Y/n]"
LANG_RETRYING="Nuovo tentativo"
LANG_ERROR_DETAIL="Dettaglio errore"
LANG_CUSTOM_TITLE="Selezione personalizzata"
LANG_CUSTOM_SPACE_TOGGLE="Spazio: alterna"
LANG_CUSTOM_ENTER_CONFIRM="Invio: conferma"
LANG_CUSTOM_A_SELECT_ALL="A: seleziona/deseleziona tutto"
LANG_CUSTOM_SELECTED="Selezionato %d/%d"
LANG_DISK_SPACE_LOW="Spazio su disco insufficiente: %sGB disponibile, almeno %sGB consigliato"
LANG_DISK_SPACE_WARNING="⚠ Spazio su disco insufficiente, l'installazione potrebbe fallire"
LANG_DISK_CHECKING="Verifica dello spazio su disco..."
LANG_NETWORK_TIMEOUT="Timeout di connessione di rete, controllare le impostazioni di rete"
LANG_NETWORK_ERROR="Errore di rete: %s"
LANG_CHECK_NETWORK="Suggerimento: Controllare la connessione di rete o impostare un proxy"
LANG_PERMISSION_DENIED="Permesso negato: %s"
LANG_PERMISSION_SUGGESTION="Suggerimento: Eseguire con sudo o contattare l'amministratore"
LANG_NEED_SUDO="Questa operazione richiede privilegi di amministratore"
LANG_NEED_ADMIN="Eseguire come amministratore"
LANG_RESUME_FOUND="Installazione incompleta trovata. Riprendere? [Y/n]"
LANG_RESUMING="Ripresa dall'ultimo checkpoint..."
LANG_CHECKPOINT_SAVED="Progresso dell'installazione salvato"
LANG_INSTALL_COMPLETE_STATE="Installazione completata, pulizia file temporanei"

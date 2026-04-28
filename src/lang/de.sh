# shellcheck shell=bash
# Quickstart-PC Language Pack: de (Deutsch)

HELP_TITLE="Quickstart-PC - Ein-Klick Computer-Einrichtung"
HELP_USAGE="Verwendung: quickstart.sh [OPTIONEN]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
Optionen:
  --lang LANG        Sprache einstellen (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  Lokaler Sprachskript-Ordner
  --cfg-path PATH    Lokale profiles.json verwenden
  --cfg-url URL      Remote profiles.json URL verwenden
  --dev              Entwicklermodus: Auswahl anzeigen ohne Installation
  --dry-run          Vorschau-Modus: Installationsprozess anzeigen ohne tatsächliche Installation
  --doctor           QC Doctor Umgebungsdiagnose ausführen
  --yes, -y          Alle Bestätigungen automatisch bestätigen
  --verbose, -v      Detaillierte Debug-Infos anzeigen
  --log-file FILE          Logs in Datei schreiben
  --export-plan FILE       Installationsplan exportieren
  --retry-failed           Zuvor fehlgeschlagene Pakete erneut versuchen
  --list-software    Alle verfügbaren Software auflisten
  --show-software ID Software-Details anzeigen
  --search KEYWORD   Software suchen
  --validate         Konfigurationsdatei validieren
  --report-json FILE JSON-Installationsbericht exportieren
  --report-txt FILE  TXT-Installationsbericht exportieren
  --list-profiles    Alle verfügbaren Profile auflisten
  --show-profile KEY Profil-Details anzeigen
  --skip SW          Angegebene Software überspringen (wiederholbar)
  --only SW          Nur angegebene Software installieren (wiederholbar)
  --fail-fast        Bei erstem Fehler stoppen
  --profile NAME     Profil direkt auswählen (Menü überspringen)
  --non-interactive  Nicht-interaktiver Modus (keine TUI/Abfragen)
  --resume                  Unterbrochene Installation fortsetzen
  --no-resume               Unterbrochene Installation nicht fortsetzen
  --update             Skript auf neueste Version aktualisieren
  --check-update            Nur nach Updates suchen
  --allow-hooks             Hook-Skripte aktivieren
  --help             Diese Hilfe anzeigen
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="Schnelle Einrichtung neuer Computer"
LANG_DETECTING_SYSTEM="Systemumgebung wird erkannt..."
LANG_SYSTEM_INFO="System"
LANG_PACKAGE_MANAGER="Paketmanager"
LANG_UNSUPPORTED_OS="Nicht unterstütztes Betriebssystem"
LANG_USING_REMOTE_CONFIG="Remote-Konfiguration wird verwendet"
LANG_USING_CUSTOM_CONFIG="Lokale Konfiguration wird verwendet"
LANG_USING_DEFAULT_CONFIG="Standardkonfiguration wird verwendet"
LANG_CONFIG_NOT_FOUND="Konfigurationsdatei nicht gefunden"
LANG_CONFIG_INVALID="Konfigurationsdatei hat ungültiges Format"
LANG_SELECT_PROFILES="Installationsprofile auswählen"
LANG_SELECT_SOFTWARE="Software zur Installation auswählen"
LANG_NAVIGATE="↑↓ Bewegen | ENTER Bestätigen"
LANG_NAVIGATE_MULTI="↑↓ Bewegen | LEERTASTE Auswählen | ENTER Bestätigen"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="Alle auswählen"
LANG_BACK_TO_PROFILES="Zurück zur Profilauswahl"
LANG_NO_PROFILE_SELECTED="Kein Profil ausgewählt"
LANG_NO_SOFTWARE_SELECTED="Keine Software ausgewählt"
LANG_CONFIRM_INSTALL="Installation bestätigen? [Y/n]"
LANG_CANCELLED="Abgebrochen"
LANG_START_INSTALLING="Software-Installation wird gestartet"
LANG_INSTALLING="Installiere"
LANG_INSTALL_SUCCESS="erfolgreich installiert"
LANG_INSTALL_FAILED="Installation fehlgeschlagen"
LANG_PLATFORM_NOT_SUPPORTED="Plattform nicht unterstützt"
LANG_INSTALLATION_COMPLETE="Installation abgeschlossen"
LANG_TOTAL_INSTALLED="Insgesamt installiert"
LANG_DEV_MODE="Entwicklermodus: Ausgewählte Software anzeigen ohne Installation"
LANG_DRY_RUN_MODE="Vorschau-Modus: Installationsprozess anzeigen ohne tatsächliche Installation"
LANG_DRY_RUN_INSTALLING="Installation simulieren"
LANG_JQ_DETECTED="jq erkannt, verwende jq"
LANG_JQ_NOT_FOUND="jq nicht gefunden, wird installiert..."
LANG_JQ_INSTALLED="jq erfolgreich installiert"
LANG_JQ_INSTALL_FAILED="jq-Installation fehlgeschlagen, versuche Fallback-Parser..."
LANG_USING_PYTHON3="Verwende python3 als Fallback-Parser"
LANG_NO_JSON_PARSER="Kein JSON-Parser verfügbar (jq/python3)"
LANG_CHECKING_INSTALLATION="Installationsstatus wird überprüft..."
LANG_SKIPPING_INSTALLED="Bereits installiert, wird übersprungen"
LANG_ALL_INSTALLED="Alle Software bereits installiert, nichts zu tun"
LANG_ASK_CONTINUE="Installation abgeschlossen. Weitere Profile installieren?"
LANG_CONTINUE="Weiter installieren"
LANG_EXIT="Beenden"
LANG_TITLE_SELECT_PROFILE="Profil auswählen"
LANG_TITLE_SELECT_SOFTWARE="Software auswählen"
LANG_TITLE_INSTALLING="Installation läuft"
LANG_TITLE_ASK_CONTINUE="Installation fortsetzen?"
LANG_LANG_PROMPT="Bitte Sprache auswählen"
LANG_LANG_MENU_ENTER="Bestätigen"
LANG_LANG_MENU_SPACE="Auswählen"
LANG_NONINTERACTIVE_ERROR="Nicht-interaktiver Modus erfordert --profile Parameter"
LANG_PROFILE_NOT_FOUND="Profil '$PROFILE_KEY' nicht gefunden"
LANG_NPM_NOT_FOUND="npm nicht gefunden, wird installiert..."
LANG_WINGET_NOT_FOUND="winget nicht gefunden, kann npm nicht automatisch installieren"
LANG_NPM_AUTO="npm"
LANG_INSTALL_FAILED_LIST="Die folgende Software konnte nicht installiert werden"
LANG_PROGRESS_INSTALLED="installiert"
LANG_PROGRESS_TO_INSTALL="zu installieren"
LANG_TIME_SECONDS="s"
LANG_TIME_TOTAL="Gesamtzeit"
LANG_RETRY_PROMPT="Erneut versuchen? [Y/n]"
LANG_RETRYING="Erneuter Versuch"
LANG_ERROR_DETAIL="Fehlerdetail"
LANG_CUSTOM_TITLE="Benutzerdefinierte Auswahl"
LANG_CUSTOM_SPACE_TOGGLE="Leertaste: umschalten"
LANG_CUSTOM_ENTER_CONFIRM="Enter: bestätigen"
LANG_CUSTOM_A_SELECT_ALL="A: alle auswählen/abwählen"
LANG_CUSTOM_SELECTED="Ausgewählt %d/%d"
LANG_DISK_SPACE_LOW="Wenig Speicherplatz: %sGB verfügbar, mindestens %sGB empfohlen"
LANG_DISK_SPACE_WARNING="⚠ Wenig Speicherplatz, Installation könnte fehlschlagen"
LANG_DISK_CHECKING="Speicherplatz wird überprüft..."
LANG_NETWORK_TIMEOUT="Netzwerkverbindung zeitüberschreitung, bitte überprüfen Sie Ihre Netzwerkeinstellungen"
LANG_NETWORK_ERROR="Netzwerkfehler: %s"
LANG_CHECK_NETWORK="Vorschlag: Überprüfen Sie die Netzwerkverbindung oder richten Sie einen Proxy ein"
LANG_PERMISSION_DENIED="Berechtigung verweigert: %s"
LANG_PERMISSION_SUGGESTION="Vorschlag: Mit sudo ausführen oder Administrator kontaktieren"
LANG_NEED_SUDO="Dieser Vorgang erfordert Administratorrechte"
LANG_NEED_ADMIN="Bitte als Administrator ausführen"
LANG_RESUME_FOUND="Unvollständige Installation gefunden. Fortsetzen? [Y/n]"
LANG_RESUMING="Fortsetzung vom letzten Checkpoint..."
LANG_CHECKPOINT_SAVED="Installationsfortschritt gespeichert"
LANG_INSTALL_COMPLETE_STATE="Installation abgeschlossen, temporäre Dateien werden bereinigt"
LANG_UPDATE_CHECKING="Suche nach Updates..."
LANG_UPDATE_AVAILABLE="Neue Version verfügbar: %s (aktuell: %s)"
LANG_UPDATE_LATEST="Bereits auf der neuesten Version"
LANG_UPDATE_DOWNLOADING="Update wird heruntergeladen..."
LANG_UPDATE_SUCCESS="Update erfolgreich! Bitte starten Sie das Skript neu"
LANG_UPDATE_FAILED="Update fehlgeschlagen: %s"
LANG_UPDATE_PROMPT="Auf neue Version aktualisieren? [Y/n]"
LANG_HOOK_RUNNING="Hook wird ausgeführt: %s"
LANG_HOOK_SUCCESS="Hook abgeschlossen"
LANG_HOOK_FAILED="Hook fehlgeschlagen: %s"
LANG_HOOKS_DISABLED="Hooks deaktiviert, verwenden Sie --allow-hooks zum Aktivieren"
LANG_HOOKS_ENABLED="Hooks aktiviert"
LANG_BATCH_INSTALLING="Batch-Installation von %d Paketen..."
LANG_BATCH_SUCCESS="Batch-Installation abgeschlossen: %d/%d erfolgreich"
LANG_BATCH_FAILED="Batch-Installation teilweise fehlgeschlagen, Rückgriff auf Einzelinstallation..."

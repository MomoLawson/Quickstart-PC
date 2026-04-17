# Quickstart-PC Language Pack: fr (Français)

HELP_TITLE="Quickstart-PC - Configuration PC en un clic"
HELP_USAGE="Utilisation : quickstart.sh [OPTIONS]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
Options :
  --lang LANG        Définir la langue (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  Dossier de scripts de langue local
  --cfg-path PATH    Utiliser le fichier profiles.json local
  --cfg-url URL      Utiliser l'URL profiles.json distante
  --dev              Mode développeur : afficher la sélection sans installer
  --dry-run          Mode aperçu : afficher le processus sans installer
  --doctor           Exécuter les diagnostics QC Doctor
  --yes, -y          Confirmer automatiquement toutes les invites
  --verbose, -v      Afficher les informations de débogage détaillées
  --log-file FILE    Écrire les journaux dans un fichier
  --export-plan FILE Exporter le plan d'installation
  --custom           Mode de sélection de logiciel personnalisé
  --retry-failed     Réessayer les paquets précédemment échoués
  --list-software    Lister tous les logiciels disponibles
  --show-software ID Afficher les détails du logiciel
  --search KEYWORD   Rechercher un logiciel
  --validate         Valider le fichier de configuration
  --report-json FILE Exporter le rapport d'installation au format JSON
  --report-txt FILE  Exporter le rapport d'installation au format TXT
  --list-profiles    Lister tous les profils disponibles
  --show-profile KEY Afficher les détails du profil
  --skip SW          Ignorer le logiciel spécifié (répétable)
  --only SW          Installer uniquement le logiciel spécifié (répétable)
  --fail-fast        Arrêter à la première erreur
  --profile NAME     Sélectionner le profil directement (ignorer le menu)
  --non-interactive  Mode non interactif (pas de TUI/invites)
  --help             Afficher ce message d'aide
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="Configuration rapide pour nouveaux ordinateurs"
LANG_DETECTING_SYSTEM="Détection de l'environnement système..."
LANG_SYSTEM_INFO="Système"
LANG_PACKAGE_MANAGER="Gestionnaire de paquets"
LANG_UNSUPPORTED_OS="Système d'exploitation non pris en charge"
LANG_USING_REMOTE_CONFIG="Utilisation de la configuration distante"
LANG_USING_CUSTOM_CONFIG="Utilisation de la configuration locale"
LANG_USING_DEFAULT_CONFIG="Utilisation de la configuration par défaut"
LANG_CONFIG_NOT_FOUND="Fichier de configuration introuvable"
LANG_CONFIG_INVALID="Format de fichier de configuration invalide"
LANG_SELECT_PROFILES="Sélectionner les profils d'installation"
LANG_SELECT_SOFTWARE="Sélectionner les logiciels à installer"
LANG_NAVIGATE="↑↓ Déplacer | ENTRÉE Confirmer"
LANG_NAVIGATE_MULTI="↑↓ Déplacer | ESPACE Sélectionner | ENTRÉE Confirmer"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="Tout sélectionner"
LANG_NO_PROFILE_SELECTED="Aucun profil sélectionné"
LANG_NO_SOFTWARE_SELECTED="Aucun logiciel sélectionné"
LANG_CONFIRM_INSTALL="Confirmer l'installation ? [Y/n]"
LANG_CANCELLED="Annulé"
LANG_START_INSTALLING="Démarrage de l'installation des logiciels"
LANG_INSTALLING="Installation"
LANG_INSTALL_SUCCESS="installé avec succès"
LANG_INSTALL_FAILED="installation échouée"
LANG_PLATFORM_NOT_SUPPORTED="Plateforme non prise en charge"
LANG_INSTALLATION_COMPLETE="Installation terminée"
LANG_TOTAL_INSTALLED="Total installé"
LANG_DEV_MODE="Mode développeur : afficher les logiciels sélectionnés sans installer"
LANG_DRY_RUN_MODE="Mode aperçu : afficher le processus sans installer"
LANG_DRY_RUN_INSTALLING="Simulation en cours"
LANG_JQ_DETECTED="jq détecté, utilisation de jq"
LANG_JQ_NOT_FOUND="jq introuvable, installation..."
LANG_JQ_INSTALLED="jq installé avec succès"
LANG_JQ_INSTALL_FAILED="Échec de l'installation de jq, essai du analyseur de secours..."
LANG_USING_PYTHON3="Utilisation de python3 comme analyseur de secours"
LANG_NO_JSON_PARSER="Aucun analyseur JSON disponible (jq/python3)"
LANG_CHECKING_INSTALLATION="Vérification de l'état d'installation..."
LANG_SKIPPING_INSTALLED="Déjà installé, passage"
LANG_ALL_INSTALLED="Tous les logiciels sont déjà installés, rien à faire"
LANG_ASK_CONTINUE="Installation terminée. Continuer l'installation d'autres profils ?"
LANG_CONTINUE="Continuer l'installation"
LANG_EXIT="Quitter"
LANG_TITLE_SELECT_PROFILE="Sélection du profil"
LANG_TITLE_SELECT_SOFTWARE="Sélection du logiciel"
LANG_TITLE_INSTALLING="Installation en cours"
LANG_TITLE_ASK_CONTINUE="Continuer l'installation ?"
LANG_LANG_PROMPT="Veuillez sélectionner la langue"
LANG_LANG_MENU_ENTER="Confirmer"
LANG_LANG_MENU_SPACE="Sélectionner"
LANG_NONINTERACTIVE_ERROR="Le mode non interactif nécessite le paramètre --profile"
LANG_PROFILE_NOT_FOUND="Profil '$PROFILE_KEY' introuvable"
LANG_NPM_NOT_FOUND="npm introuvable, installation..."
LANG_WINGET_NOT_FOUND="winget introuvable, impossible d installer npm automatiquement"
LANG_NPM_AUTO="npm"

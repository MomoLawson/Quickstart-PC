# shellcheck shell=bash
# Quickstart-PC Language Pack: en-US (English)

HELP_TITLE="Quickstart-PC - One-click computer setup"
HELP_USAGE="Usage: quickstart.sh [OPTIONS]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
Options:
  --lang LANG        Set language (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  Use local language script folder
  --cfg-path PATH    Use local profiles.json file
  --cfg-url URL      Use remote profiles.json URL
  --dev              Dev mode: show selections without installing
  --dry-run          Preview mode: Show process without installing
  --doctor          Run QC Doctor environment diagnostics
  --yes, -y          Auto-confirm all prompts
  --verbose, -v      Show detailed debug info
  --log-file FILE    Write logs to file
  --export-plan FILE Export installation plan to file
  --custom           Custom software selection mode
  --retry-failed     Retry previously failed packages
  --list-software    List all available software
  --show-software ID Show software details
  --search KEYWORD   Search software
  --validate         Validate configuration file
  --report-json FILE Export JSON installation report
  --report-txt FILE  Export TXT installation report
  --list-profiles    List all available profiles
  --show-profile KEY Show profile details
  --skip SW          Skip specified software (repeatable)
  --only SW          Only install specified software (repeatable)
  --fail-fast        Stop on first error
  --profile NAME     Select profile directly (skip menu)
  --non-interactive  Non-interactive mode (no TUI/prompts)
  --help             Show this help message
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="Quick setup for new computers"
LANG_DETECTING_SYSTEM="Detecting system environment..."
LANG_SYSTEM_INFO="System"
LANG_PACKAGE_MANAGER="Package Manager"
LANG_UNSUPPORTED_OS="Unsupported operating system"
LANG_USING_REMOTE_CONFIG="Using remote configuration"
LANG_USING_CUSTOM_CONFIG="Using local configuration"
LANG_USING_DEFAULT_CONFIG="Using default configuration"
LANG_CONFIG_NOT_FOUND="Configuration file not found"
LANG_CONFIG_INVALID="Configuration file format invalid"
LANG_SELECT_PROFILES="Select Installation Profiles"
LANG_SELECT_SOFTWARE="Select Software to Install"
LANG_NAVIGATE="↑↓ Move | ENTER Confirm"
LANG_NAVIGATE_MULTI="↑↓ Move | SPACE Select | ENTER Confirm"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="Select All"
LANG_BACK_TO_PROFILES="Back to Profiles"
LANG_NO_PROFILE_SELECTED="No profile selected"
LANG_NO_SOFTWARE_SELECTED="No software selected"
LANG_CONFIRM_INSTALL="Confirm installation? [Y/n]"
LANG_CANCELLED="Cancelled"
LANG_START_INSTALLING="Starting software installation"
LANG_INSTALLING="Installing"
LANG_INSTALL_SUCCESS="installed successfully"
LANG_INSTALL_FAILED="installation failed"
LANG_PLATFORM_NOT_SUPPORTED="Platform not supported"
LANG_INSTALLATION_COMPLETE="Installation Complete"
LANG_TOTAL_INSTALLED="Total installed"
LANG_DEV_MODE="Dev mode: Show selected software without installing"
LANG_DRY_RUN_MODE="Preview mode: Show process without installing"
LANG_DRY_RUN_INSTALLING="Simulating install"
LANG_JQ_DETECTED="jq detected, using jq"
LANG_JQ_NOT_FOUND="jq not found, installing..."
LANG_JQ_INSTALLED="jq installed successfully"
LANG_JQ_INSTALL_FAILED="jq installation failed, trying fallback parser..."
LANG_USING_PYTHON3="Using python3 as fallback parser"
LANG_NO_JSON_PARSER="No JSON parser available (jq/python3)"
LANG_CHECKING_INSTALLATION="Checking installation status..."
LANG_SKIPPING_INSTALLED="Already installed, skipping"
LANG_ALL_INSTALLED="All software already installed, nothing to do"
LANG_ASK_CONTINUE="Installation complete. Continue installing other profiles?"
LANG_CONTINUE="Continue"
LANG_EXIT="Exit"
LANG_TITLE_SELECT_PROFILE="Select Profile"
LANG_TITLE_SELECT_SOFTWARE="Select Software"
LANG_TITLE_INSTALLING="Installing"
LANG_TITLE_ASK_CONTINUE="Continue Installing?"
LANG_LANG_PROMPT="Please select language"
LANG_LANG_MENU_ENTER="Confirm"
LANG_LANG_MENU_SPACE="Select"
LANG_NONINTERACTIVE_ERROR="Non-interactive mode requires --profile parameter"
LANG_PROFILE_NOT_FOUND="Profile '$PROFILE_KEY' not found"
LANG_NPM_NOT_FOUND="npm not found, installing..."
LANG_WINGET_NOT_FOUND="winget not found, cannot auto-install npm"
LANG_NPM_AUTO="npm"
LANG_INSTALL_FAILED_LIST="The following software failed to install"
LANG_PROGRESS_INSTALLED="installed"
LANG_PROGRESS_TO_INSTALL="to install"
LANG_TIME_SECONDS="s"
LANG_TIME_TOTAL="Total time"
LANG_RETRY_PROMPT="Retry? [Y/n]"
LANG_RETRYING="Retrying"
LANG_ERROR_DETAIL="Error detail"
LANG_CUSTOM_TITLE="Custom Software Selection"
LANG_CUSTOM_SPACE_TOGGLE="Space: toggle"
LANG_CUSTOM_ENTER_CONFIRM="Enter: confirm"
LANG_CUSTOM_A_SELECT_ALL="A: select/deselect all"
LANG_CUSTOM_SELECTED="Selected %d/%d"
LANG_DISK_SPACE_LOW="Low disk space: %sGB available, at least %sGB recommended"
LANG_DISK_SPACE_WARNING="⚠ Low disk space, installation may fail"
LANG_DISK_CHECKING="Checking disk space..."
LANG_NETWORK_TIMEOUT="Network connection timed out, please check your network"
LANG_NETWORK_ERROR="Network error: %s"
LANG_CHECK_NETWORK="Suggestion: Check network connection or set proxy"
LANG_PERMISSION_DENIED="Permission denied: %s"
LANG_PERMISSION_SUGGESTION="Suggestion: Run with sudo or contact your administrator"
LANG_NEED_SUDO="This operation requires administrator privileges"
LANG_NEED_ADMIN="Please run as Administrator"
LANG_RESUME_FOUND="Incomplete installation found. Resume? [Y/n]"
LANG_RESUMING="Resuming from last checkpoint..."
LANG_CHECKPOINT_SAVED="Installation progress saved"
LANG_INSTALL_COMPLETE_STATE="Installation complete, cleaning up"

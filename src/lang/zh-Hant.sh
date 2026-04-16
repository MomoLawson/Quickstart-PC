# Quickstart-PC Language Pack: zh-Hant (繁體中文)

HELP_TITLE="Quickstart-PC - 一鍵配置新電腦"
HELP_USAGE="用法: quickstart.sh [選項]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
選項:
  --lang LANG        設置語言 (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  使用本地语言脚本文件夹
  --cfg-path PATH    使用本地 profiles.json 文件
  --cfg-url URL      使用遠程 profiles.json URL
  --dev              開發模式：僅顯示選擇的軟體，不安裝
  --dry-run          預覽模式：展示安裝過程但不實際安裝
  --yes, -y          自動確認所有提示
  --verbose, -v      顯示詳細調試信息
  --log-file FILE    將日誌寫入文件
  --export-plan FILE 導出安裝計劃到文件
  --custom           自定義軟體選擇模式
  --retry-failed     重試之前失敗的軟體
  --list-software    列出所有可用軟體
  --show-software ID 顯示指定軟體詳情
  --search KEYWORD   搜索軟體
  --validate         校驗配置文件
  --report-json FILE 導出 JSON 格式安裝報告
  --report-txt FILE  導出 TXT 格式安裝報告
  --list-profiles    列出所有可用套餐
  --show-profile KEY 顯示指定套餐詳情
  --skip SW          跳過指定軟體（可多次使用）
  --only SW          只安裝指定軟體（可多次使用）
  --fail-fast        遇到錯誤時立即停止
  --profile NAME     直接指定安裝套餐（跳過選擇菜單）
  --non-interactive  非交互模式（禁止所有 TUI/prompt）
  --help             顯示此幫助信息
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="快速配置新電腦軟體環境"
LANG_DETECTING_SYSTEM="檢測系統環境..."
LANG_SYSTEM_INFO="系統"
LANG_PACKAGE_MANAGER="包管理器"
LANG_UNSUPPORTED_OS="不支持的操作系統"
LANG_USING_REMOTE_CONFIG="使用遠程配置"
LANG_USING_CUSTOM_CONFIG="使用本地配置"
LANG_USING_DEFAULT_CONFIG="使用默認配置"
LANG_CONFIG_NOT_FOUND="配置文件不存在"
LANG_CONFIG_INVALID="配置文件格式無效"
LANG_SELECT_PROFILES="選擇安裝套餐"
LANG_SELECT_SOFTWARE="選擇要安裝的軟體"
LANG_NAVIGATE="↑↓ 移動 | 回車 確認"
LANG_NAVIGATE_MULTI="↑↓ 移動 | 空格 選擇 | 回車 確認"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="全選"
LANG_NO_PROFILE_SELECTED="未選擇任何套餐"
LANG_NO_SOFTWARE_SELECTED="未選擇任何軟體"
LANG_CONFIRM_INSTALL="確認安裝？[Y/n]"
LANG_CANCELLED="已取消"
LANG_START_INSTALLING="開始安裝軟體"
LANG_INSTALLING="安裝"
LANG_INSTALL_SUCCESS="安裝完成"
LANG_INSTALL_FAILED="安裝失敗"
LANG_PLATFORM_NOT_SUPPORTED="不支持的平台"
LANG_INSTALLATION_COMPLETE="安裝完成"
LANG_TOTAL_INSTALLED="共安裝"
LANG_DEV_MODE="開發者模式：僅顯示選擇的軟體，不安裝"
LANG_DRY_RUN_MODE="預覽模式：展示安裝過程但不實際安裝"
LANG_DRY_RUN_INSTALLING="模擬安裝"
LANG_JQ_DETECTED="檢測到 jq，使用 jq"
LANG_JQ_NOT_FOUND="未檢測到 jq，安裝中..."
LANG_JQ_INSTALLED="jq 安裝成功"
LANG_JQ_INSTALL_FAILED="jq 安裝失敗，嘗試使用備用解析方案..."
LANG_USING_PYTHON3="使用 python3 作為備用解析器"
LANG_NO_JSON_PARSER="無可用 JSON 解析器 (jq/python3)"
LANG_CHECKING_INSTALLATION="正在檢測安裝情況..."
LANG_SKIPPING_INSTALLED="已安裝，跳過"
LANG_ALL_INSTALLED="所有軟體均已安裝，無需操作"
LANG_ASK_CONTINUE="安裝完成，是否繼續安裝其他套餐？"
LANG_CONTINUE="繼續安裝"
LANG_EXIT="退出"
LANG_TITLE_SELECT_PROFILE="選擇套餐"
LANG_TITLE_SELECT_SOFTWARE="選擇軟體"
LANG_TITLE_INSTALLING="安裝中"
LANG_TITLE_ASK_CONTINUE="是否繼續安裝"
LANG_LANG_PROMPT="請選擇語言"
LANG_LANG_MENU_ENTER="確認"
LANG_LANG_MENU_SPACE="選擇"
LANG_NONINTERACTIVE_ERROR="非交互模式需要 --profile 參數"
LANG_PROFILE_NOT_FOUND="Profile '$PROFILE_KEY' 不存在"
LANG_NPM_NOT_FOUND="npm 未安裝，正在安裝..."
LANG_WINGET_NOT_FOUND="winget 未找到，無法自動安裝 npm"
LANG_NPM_AUTO="npm"

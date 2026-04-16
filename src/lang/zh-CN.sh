# Quickstart-PC Language Pack: zh-CN (Chinese Simplified)

HELP_TITLE="Quickstart-PC - 一键配置新电脑"
HELP_USAGE="用法: quickstart.sh [选项]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
选项:
  --lang LANG        设置语言 (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  使用本地语言脚本文件夹
  --cfg-path PATH    使用本地 profiles.json 文件
  --cfg-url URL      使用远程 profiles.json URL
  --dev              开发模式：显示选择的软件但不安装
 --dry-run 预览模式：展示安装过程但不实际安装
  --yes, -y          自动确认所有提示
  --verbose, -v      显示详细调试信息
  --log-file FILE    将日志写入文件
  --export-plan FILE 导出安装计划到文件
  --custom           自定义软件选择模式
  --retry-failed     重试之前失败的软件
  --list-software    列出所有可用软件
  --show-software ID 显示指定软件详情
  --search KEYWORD   搜索软件
  --validate         校验配置文件
  --report-json FILE 导出 JSON 格式安装报告
  --report-txt FILE  导出 TXT 格式安装报告
  --list-profiles    列出所有可用套餐
  --show-profile KEY 显示指定套餐详情
  --skip SW          跳过指定软件（可多次使用）
  --only SW          只安装指定软件（可多次使用）
  --fail-fast        遇到错误时立即停止
  --profile NAME     直接指定安装套餐（跳过选择菜单）
  --non-interactive  非交互模式（禁止所有 TUI/prompt）
  --help             显示此帮助信息
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="快速配置新电脑软件环境"
LANG_DETECTING_SYSTEM="检测系统环境..."
LANG_SYSTEM_INFO="系统"
LANG_PACKAGE_MANAGER="包管理器"
LANG_UNSUPPORTED_OS="不支持的操作系统"
LANG_USING_REMOTE_CONFIG="使用远程配置"
LANG_USING_CUSTOM_CONFIG="使用本地配置"
LANG_USING_DEFAULT_CONFIG="使用默认配置"
LANG_CONFIG_NOT_FOUND="配置文件不存在"
LANG_CONFIG_INVALID="配置文件格式无效"
LANG_SELECT_PROFILES="选择安装套餐"
LANG_SELECT_SOFTWARE="选择要安装的软件"
LANG_NAVIGATE="↑↓ 移动 | 回车 确认"
LANG_NAVIGATE_MULTI="↑↓ 移动 | 空格 选择 | 回车 确认"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="全选"
LANG_NO_PROFILE_SELECTED="未选择任何套餐"
LANG_NO_SOFTWARE_SELECTED="未选择任何软件"
LANG_CONFIRM_INSTALL="确认安装？[Y/n]"
LANG_CANCELLED="已取消"
LANG_START_INSTALLING="开始安装软件"
LANG_INSTALLING="安装"
LANG_INSTALL_SUCCESS="安装完成"
LANG_INSTALL_FAILED="安装失败"
LANG_PLATFORM_NOT_SUPPORTED="不支持的平台"
LANG_INSTALLATION_COMPLETE="安装完成"
LANG_TOTAL_INSTALLED="共安装"
LANG_DEV_MODE="开发者模式：仅显示选择的软件，不实际安装"
LANG_DRY_RUN_MODE="预览模式：展示安装过程但不实际安装"
LANG_DRY_RUN_INSTALLING="模拟安装"
LANG_JQ_DETECTED="检测到 jq，使用 jq"
LANG_JQ_NOT_FOUND="未检测到 jq，安装中..."
LANG_JQ_INSTALLED="jq 安装成功"
LANG_JQ_INSTALL_FAILED="jq 安装失败，尝试使用备用解析方案..."
LANG_USING_PYTHON3="使用 python3 作为备用解析器"
LANG_NO_JSON_PARSER="无可用 JSON 解析器 (jq/python3)"
LANG_CHECKING_INSTALLATION="正在检测安装情况..."
LANG_SKIPPING_INSTALLED="已安装，跳过"
LANG_ALL_INSTALLED="所有软件均已安装，无需操作"
LANG_ASK_CONTINUE="安装完成，是否继续安装其他套餐？"
LANG_CONTINUE="继续安装"
LANG_EXIT="退出"
LANG_TITLE_SELECT_PROFILE="选择套餐"
LANG_TITLE_SELECT_SOFTWARE="选择软件"
LANG_TITLE_INSTALLING="安装中"
LANG_TITLE_ASK_CONTINUE="是否继续安装"
LANG_LANG_PROMPT="请选择语言"
LANG_LANG_MENU_ENTER="确认"
LANG_LANG_MENU_SPACE="选择"
LANG_NONINTERACTIVE_ERROR="非交互模式需要 --profile 参数"
LANG_PROFILE_NOT_FOUND="Profile '$PROFILE_KEY' 不存在"
LANG_NPM_NOT_FOUND="npm 未安装，正在安装..."
LANG_WINGET_NOT_FOUND="winget 未找到，无法自动安装 npm"
LANG_NPM_AUTO="npm"

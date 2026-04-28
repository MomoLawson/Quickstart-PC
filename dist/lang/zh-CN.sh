# shellcheck shell=bash
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
 --doctor 运行 QC Doctor 环境诊断
  --yes, -y          自动确认所有提示
  --verbose, -v      显示详细调试信息
  --log-file FILE          将日志写入文件
  --export-plan FILE       导出安装计划到文件
  --retry-failed           重试之前失败的软件
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
  --resume                  恢复中断的安装
  --no-resume               不恢复中断的安装
  --update             更新脚本到最新版本
  --check-update            检查更新但不安装
  --allow-hooks             启用钩子脚本执行
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
LANG_BACK_TO_PROFILES="返回套餐选择"
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
LANG_INSTALL_FAILED_LIST="以下软件安装失败"
LANG_PROGRESS_INSTALLED="已安装"
LANG_PROGRESS_TO_INSTALL="待安装"
LANG_TIME_SECONDS="秒"
LANG_TIME_TOTAL="总耗时"
LANG_RETRY_PROMPT="是否重试？[Y/n]"
LANG_RETRYING="重试中"
LANG_ERROR_DETAIL="错误详情"
LANG_CUSTOM_TITLE="自定义选择软件"
LANG_CUSTOM_SPACE_TOGGLE="空格: 切换选择"
LANG_CUSTOM_ENTER_CONFIRM="回车: 确认"
LANG_CUSTOM_A_SELECT_ALL="A: 全选/全不选"
LANG_CUSTOM_SELECTED="已选择 %d/%d"
LANG_DISK_SPACE_LOW="磁盘空间不足: 可用 %sGB，建议至少 %sGB"
LANG_DISK_SPACE_WARNING="⚠ 磁盘空间较低，安装可能失败"
LANG_DISK_CHECKING="检查磁盘空间..."
LANG_NETWORK_TIMEOUT="网络连接超时，请检查网络设置"
LANG_NETWORK_ERROR="网络错误: %s"
LANG_CHECK_NETWORK="建议: 检查网络连接或设置代理"
LANG_PERMISSION_DENIED="权限不足: %s"
LANG_PERMISSION_SUGGESTION="建议: 使用 sudo 运行或联系管理员"
LANG_NEED_SUDO="此操作需要管理员权限"
LANG_NEED_ADMIN="请以管理员身份运行"
LANG_RESUME_FOUND="发现未完成的安装，是否继续？[Y/n]"
LANG_RESUMING="从上次中断处继续安装..."
LANG_CHECKPOINT_SAVED="安装进度已保存"
LANG_INSTALL_COMPLETE_STATE="安装完成，清理临时文件"
LANG_UPDATE_CHECKING="检查更新..."
LANG_UPDATE_AVAILABLE="发现新版本: %s (当前: %s)"
LANG_UPDATE_LATEST="已是最新版本"
LANG_UPDATE_DOWNLOADING="下载更新..."
LANG_UPDATE_SUCCESS="更新成功！请重新运行脚本"
LANG_UPDATE_FAILED="更新失败: %s"
LANG_UPDATE_PROMPT="是否更新到新版本？[Y/n]"
LANG_HOOK_RUNNING="执行钩子: %s"
LANG_HOOK_SUCCESS="钩子执行完成"
LANG_HOOK_FAILED="钩子执行失败: %s"
LANG_HOOKS_DISABLED="钩子脚本已禁用，使用 --allow-hooks 启用"
LANG_HOOKS_ENABLED="钩子脚本已启用"
LANG_BATCH_INSTALLING="批量安装 %d 个软件..."
LANG_BATCH_SUCCESS="批量安装完成: %d/%d 成功"
LANG_BATCH_FAILED="批量安装部分失败，回退逐个安装..."

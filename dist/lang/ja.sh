# shellcheck shell=bash
# Quickstart-PC Language Pack: ja (Japanese)

HELP_TITLE="Quickstart-PC - ワンクリックPC設定"
HELP_USAGE="使用方法: quickstart.sh [オプション]"
HELP_OPTIONS=""
read -r -d '' HELP_OPTIONS << 'OPTIONS_EOF'
オプション:
  --lang LANG        言語を設定 (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)
  --local-lang PATH  ローカル言語スクリプトフォルダを使用
  --cfg-path PATH    ローカルの profiles.json を使用
  --cfg-url URL      リモートの profiles.json URL を使用
  --dev              開発モード：選択したソフトを表示但不インストール
  --dry-run          プレビューモード：インストール過程を表示但不实际インストール
  --doctor QC        Doctor環境診断を実行
  --yes, -y         全てのプロンプトに自動同意
  --verbose, -v      詳細なデバッグ情報を表示
  --log-file FILE    ログをファイルに書き込む
  --export-plan FILE インストール計画をエクスポート
  --custom           カスタムソフトウェア選択モード
  --retry-failed     以前に失敗したパッケージを再試行
  --list-software    全ての利用可能なソフトウェアをリスト表示
  --show-software ID 指定したソフトウェアの詳細を表示
  --search KEYWORD   ソフトウェアを検索
  --validate         設定ファイルを検証
  --report-json FILE JSONフォーマットでインストールレポートをエクスポート
  --report-txt FILE  TXTフォーマットでインストールレポートをエクスポート
  --list-profiles     全ての利用可能なプロファイルをリスト表示
  --show-profile KEY 指定したプロファイルの詳細を表示
  --skip SW          指定したソフトウェアをスキップ（重复可能）
  --only SW          指定したソフトウェアのみインストール（重复可能）
  --fail-fast        最初のエラーで停止
  --profile NAME     プロファイルを直接指定（スキップメニュー）
  --non-interactive  非インタラクティブモード（TUI/プロンプト全て無効）
  --help             このヘルプを表示
OPTIONS_EOF

LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
LANG_BANNER_DESC="新PCのソフトウェア環境を素早く設定"
LANG_DETECTING_SYSTEM="システム環境を検出中..."
LANG_SYSTEM_INFO="システム"
LANG_PACKAGE_MANAGER="パッケージマネージャー"
LANG_UNSUPPORTED_OS="サポートされていないOS"
LANG_USING_REMOTE_CONFIG="リモート設定を使用"
LANG_USING_CUSTOM_CONFIG="ローカル設定を使用"
LANG_USING_DEFAULT_CONFIG="デフォルト設定を使用"
LANG_CONFIG_NOT_FOUND="設定ファイルが見つかりません"
LANG_CONFIG_INVALID="設定ファイルの形式が無効です"
LANG_SELECT_PROFILES="インストールプロファイルを選択"
LANG_SELECT_SOFTWARE="インストールするソフトウェアを選択"
LANG_NAVIGATE="↑↓ 移動 | Enter 確定"
LANG_NAVIGATE_MULTI="↑↓ 移動 | スペース 選択 | Enter 確定"
LANG_SELECTED="[✓] "
LANG_NOT_SELECTED="[  ] "
LANG_SELECT_ALL="全て選択"
LANG_BACK_TO_PROFILES="プロファイル選択に戻る"
LANG_NO_PROFILE_SELECTED="プロファイルが選択されていません"
LANG_NO_SOFTWARE_SELECTED="ソフトウェアが選択されていません"
LANG_CONFIRM_INSTALL="インストールを確定しますか？[Y/n]"
LANG_CANCELLED="キャンセルされました"
LANG_START_INSTALLING="ソフトウェアのインストールを開始"
LANG_INSTALLING="インストール中"
LANG_INSTALL_SUCCESS="インストール完了"
LANG_INSTALL_FAILED="インストール失敗"
LANG_PLATFORM_NOT_SUPPORTED="サポートされていないプラットフォーム"
LANG_INSTALLATION_COMPLETE="インストール完了"
LANG_TOTAL_INSTALLED="合計インストール"
LANG_DEV_MODE="開発モード：選択したソフトウェアを表示但不インストール"
LANG_DRY_RUN_MODE="プレビューモード：インストール過程を表示但不实际インストール"
LANG_DRY_RUN_INSTALLING="インストールをシミュレート"
LANG_JQ_DETECTED="jq を検出、jqを使用"
LANG_JQ_NOT_FOUND="jq が見つかりません、インストール中..."
LANG_JQ_INSTALLED="jq のインストール成功"
LANG_JQ_INSTALL_FAILED="jq のインストール失敗、替代パーザーを試用..."
LANG_USING_PYTHON3="python3 を替代パーサーとして使用"
LANG_NO_JSON_PARSER="利用可能なJSONパーサーがありません (jq/python3)"
LANG_CHECKING_INSTALLATION="インストール狀態を確認中..."
LANG_SKIPPING_INSTALLED="インストール済み、スキップ"
LANG_ALL_INSTALLED="全てのソフトウェアがインストール済み、操作不要"
LANG_ASK_CONTINUE="インストール完了。其他プロファイルをインストールしますか？"
LANG_CONTINUE="続ける"
LANG_EXIT="終了"
LANG_TITLE_SELECT_PROFILE="プロファイル選択"
LANG_TITLE_SELECT_SOFTWARE="ソフトウェア選択"
LANG_TITLE_INSTALLING="インストール中"
LANG_TITLE_ASK_CONTINUE="インストールを続けますか？"
LANG_LANG_PROMPT="言語を選択してください"
LANG_LANG_MENU_ENTER="確定"
LANG_LANG_MENU_SPACE="選択"
LANG_NONINTERACTIVE_ERROR="非インタラクティブモードでは --profile パラメータが必要です"
LANG_PROFILE_NOT_FOUND="プロファイル '$PROFILE_KEY' が見つかりません"
LANG_NPM_NOT_FOUND="npm がありません、インストール中..."
LANG_WINGET_NOT_FOUND="winget が見つかりません、npmを自動インストールできません"
LANG_NPM_AUTO="npm"
LANG_INSTALL_FAILED_LIST="以下のソフトウェアのインストールに失敗しました"
LANG_PROGRESS_INSTALLED="インストール済み"
LANG_PROGRESS_TO_INSTALL="インストール予定"
LANG_TIME_SECONDS="秒"
LANG_TIME_TOTAL="合計時間"
LANG_RETRY_PROMPT="再試行しますか？[Y/n]"
LANG_RETRYING="再試行中"
LANG_ERROR_DETAIL="エラー詳細"
LANG_CUSTOM_TITLE="カスタムソフトウェア選択"
LANG_CUSTOM_SPACE_TOGGLE="スペース: 切り替え"
LANG_CUSTOM_ENTER_CONFIRM="Enter: 確認"
LANG_CUSTOM_A_SELECT_ALL="A: 全選択/全解除"
LANG_CUSTOM_SELECTED="選択済み %d/%d"

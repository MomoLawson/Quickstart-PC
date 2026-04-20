# 第一梯队功能开发计划

## TL;DR
> **目标**: 实现 4 个用户体验提升功能：安装进度条、安装耗时统计、安装失败重试、软件分类标签
>
> **交付物**:
> - 安装时显示进度条 `████░░░░ 3/8 Firefox - 安装中...`
> - 每个软件安装后显示耗时 `3.2s`，安装结束显示总耗时
> - 安装失败时提示重试 `是否重试？[Y/n]`
> - 软件选择菜单中软件名前显示分类图标 `🌐 Firefox`
>
> **预估工作量**: Large
> **并行执行**: YES - 4 waves
> **关键路径**: Bug修复(#0) → 进度条(#1) → 耗时统计(#2) → 重试提示(#4) → 分类标签(#5)

---

## Context

### 原始需求
用户要求实现第一梯队体验提升功能（#3 已确认无问题，排除）：
1. 安装进度条
2. 安装耗时统计
4. 安装失败重试提示
5. 软件分类标签

每个功能完成后单独提交一个版本。

### 代码现状
- `install_software()` 有重复代码 bug：1533-1539 和 1541-1547 是重复的安装逻辑，命令被执行了两次
- `main()` 安装循环（1975-2013行）逐行刷 `[✓]`/`[→]`，无进度感知
- 安装失败消息 `以下软件安装失败` 硬编码中文（行2011）
- 软件选择菜单的 `menu_names` 由 `sw_data` 构建，目前只有 `name - desc` 格式

### Metis Review
**识别的风险**:
- 进度条实现要注意 bash 3.2 兼容性（macOS），不能用 `printf '%*s'` 的某些高级特性
- `install_software()` 重复执行命令是严重 bug，必须先修
- 分类图标需要修改 `profiles.json` 中每个软件条目，影响面大，需谨慎

---

## Work Objectives

### 核心目标
提升安装过程的可感知性和交互友好度

### 具体交付物
- 修复 `install_software()` 重复执行 bug
- 安装进度条（检测阶段 + 安装阶段）
- 安装耗时统计（单软件 + 总计）
- 安装失败重试交互
- 软件分类标签

### 完成标准
- [ ] `install_software()` 每个命令只执行一次
- [ ] 安装时能看到进度 `██░░░░ 3/8`
- [ ] 每个软件安装完显示耗时
- [ ] 安装失败时出现重试提示
- [ ] 软件菜单中显示分类图标

### Must Have
- 所有新 UI 文本走 LANG 国际化变量
- macOS bash 3.2 兼容
- 方向键同时支持 `[A`/`OA` 格式
- 每个功能完成后单独 build + commit + push + release

### Must NOT Have
- 不能引入外部依赖（如 `pv` 命令）
- 不能修改 PowerShell 脚本（用户说"以后继续"）
- 不能改变 profiles.json 的核心结构（只添加 category 字段）

---

## Verification Strategy

### 测试决策
- **基础设施存在**: YES (项目有 GitHub Actions CI)
- **自动化测试**: Tests-after（功能完成后手动验证 + dry-run）
- **框架**: bash dry-run 模式验证

### QA 策略
每个任务完成后用 `--dry-run` 模式验证 UI 显示正确：
- `bash dist/quickstart.sh --dry-run --profile recommended --lang zh`
- `bash dist/quickstart.sh --dry-run --profile recommended --lang en`

---

## Execution Strategy

### 并行执行波次

```
Wave 1 (基础修复 - 必须先完成):
└── Task 0: 修复 install_software() 重复执行 bug [quick]

Wave 2 (安装体验 - 顺序执行，每步依赖上一步):
├── Task 1: 安装进度条 (depends: 0) [unspecified-high]
├── Task 2: 安装耗时统计 (depends: 1) [unspecified-high]
└── Task 4: 安装失败重试提示 (depends: 2) [unspecified-high]

Wave 3 (独立功能):
└── Task 5: 软件分类标签 (depends: 0) [unspecified-high]

Wave FINAL (验证):
└── F1: 完整 dry-run 测试 [quick]
```

关键路径: Task 0 → Task 1 → Task 2 → Task 4
版本计划: v0.64.0 (进度条) → v0.65.0 (耗时统计) → v0.66.0 (重试) → v0.67.0 (分类标签)

---

## TODOs

- [ ] 0. 修复 install_software() 重复执行 bug

  **What to do**:
  - 删除 `install_software()` 中 1541-1547 行的重复代码（`log_step` + 第二次 `eval "$cmd"`）
  - 只保留 1533-1539 的 `log_to_file` + 单次 `eval "$cmd"` 逻辑
  - 成功返回 0，失败返回 1

  **Must NOT do**:
  - 不改变 dry-run 分支的逻辑（1525-1531 行保持不变）
  - 不修改 `install_software()` 的函数签名

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []
  - 原因: 纯删除重复代码，改动极小

  **Parallelization**:
  - **Can Run In Parallel**: NO（后续任务依赖此修复）
  - **Blocks**: Tasks 1, 2, 4, 5
  - **Blocked By**: None

  **References**:
  - `src/quickstart.sh:1506-1548` — `install_software()` 完整实现
  - 1525-1531: dry-run 分支（保持不变）
  - 1533-1539: 正确的安装逻辑（保留）
  - 1541-1547: 重复的安装逻辑（删除）

  **Acceptance Criteria**:
  - [ ] `install_software()` 中 `eval "$cmd"` 只出现一次（dry-run 分支除外）
  - [ ] `bash scripts/build.sh` 成功

  **QA Scenarios**:
  ```
  Scenario: dry-run 模式安装 Firefox
  Tool: Bash
  Steps:
    1. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
    2. 检查输出中没有重复的安装步骤
  Expected Result: 每个软件只出现一次安装输出
  Evidence: .sisyphus/evidence/task-0-dry-run.txt
  ```

  **Commit**: YES
  - Message: `fix: install_software() 重复执行安装命令`
  - Files: `src/quickstart.sh`
  - Pre-commit: `bash scripts/build.sh`

---

- [ ] 1. 安装进度条

  **What to do**:

  **1.1 添加 LANG 变量到所有 10 个语言文件**:
  - `LANG_PROGRESS_INSTALLED` — 已安装标记（zh: "已安装" / en: "installed"）
  - `LANG_PROGRESS_TO_INSTALL` — 待安装标记（zh: "待安装" / en: "to install"）
  - `LANG_PROGRESS_CHECKING` — 检测中（zh: "检测中" / en: "Checking"）

  **1.2 在 `quickstart.sh` 中添加 `draw_progress_bar()` 辅助函数**:
  ```bash
  draw_progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-20}
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo "$bar"
  }
  ```

  **1.3 重写检测阶段（main() 1983-1993行）**:
  把逐行刷 `[✓]`/`[→]` 改为：先静默检测所有软件，然后用一行摘要显示：
  ```
  检测中... ████████████░░░░░░░░ 3/8 已安装, 5 待安装
  ```
  实现方式：
  - 检测循环中不 echo，只填充 `already_installed` 和 `to_install` 数组
  - 检测完后用 `draw_progress_bar` 输出一行摘要
  - 然后列出已安装的软件名（灰色）

  **1.4 重写安装循环（main() 1997-2008行）**:
  每个软件安装时显示：
  ```
  ████████░░░░░░░░░░░░ 3/8 Firefox - 安装中...
  ```
  安装完成后用 `\r` 回到行首覆写为：
  ```
  ██████████░░░░░░░░░░ 4/8 Firefox - 安装完成
  ```

  实现方式：
  ```bash
  local total=${#to_install[@]}
  local current=0
  for sw in "${to_install[@]}"; do
    current=$((current + 1))
    local bar=$(draw_progress_bar $current $total 20)
    local sw_name=$(json_get_software_field "$CONFIG_FILE" "$sw" "name")
    printf "\r  %s %d/%d %s - %s..." "$bar" "$current" "$total" "$sw_name" "$LANG_INSTALLING"
    if install_software "$CONFIG_FILE" "$os" "$sw"; then
      printf "\r  %s %d/%d %s - %s  \n" "$bar" "$current" "$total" "$sw_name" "$LANG_INSTALL_SUCCESS"
    else
      printf "\r  %s %d/%d %s - %s  \n" "$bar" "$current" "$total" "$sw_name" "$LANG_INSTALL_FAILED"
      install_failed+=("$sw_name")
    fi
  done
  ```

  **1.5 更新 `--dry-run` 模式**:
  dry-run 模式也显示进度条，但用 `CYAN` 颜色和 `(simulated)` 标记

  **Must NOT do**:
  - 不修改 `install_software()` 内部逻辑（Task 0 已处理）
  - 不修改 PowerShell 脚本
  - 不使用 `pv` 或其他外部依赖

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []
  - 原因: 涉及 UI 重写、多文件修改（10 个语言文件 + 主脚本），需要细心处理

  **Parallelization**:
  - **Can Run In Parallel**: NO（依赖 Task 0）
  - **Blocks**: Task 2, Task 4
  - **Blocked By**: Task 0

  **References**:
  - `src/quickstart.sh:1975-2013` — main() 中的检测和安装循环
  - `src/quickstart.sh:1506-1531` — install_software() dry-run 分支
  - `src/lang/en-US.sh:77-79` — LANG_CHECKING_INSTALLATION, LANG_SKIPPING_INSTALLED, LANG_ALL_INSTALLED
  - `src/lang/zh-CN.sh:77-79` — 同上中文版
  - `src/lang/*.sh` — 其余 8 个语言文件，需同步添加新变量

  **Acceptance Criteria**:
  - [ ] `draw_progress_bar()` 函数已添加
  - [ ] 检测阶段显示一行进度摘要而非逐行输出
  - [ ] 安装阶段每行显示 `██░░ 2/8 软件名 - 状态`
  - [ ] 10 个语言文件均添加了新 LANG 变量
  - [ ] `bash scripts/build.sh` 成功
  - [ ] `--dry-run` 模式也显示进度条

  **QA Scenarios**:
  ```
  Scenario: 进度条正常显示
  Tool: Bash
  Steps:
    1. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
    2. 检查输出中包含 █ 和 ░ 字符
    3. 检查输出中包含 N/N 格式的进度数字
  Expected Result: 输出包含进度条和计数
  Evidence: .sisyphus/evidence/task-1-progress-bar.txt

  Scenario: 英文模式进度条
  Tool: Bash
  Steps:
    1. bash dist/quickstart.sh --dry-run --profile recommended --lang en --non-interactive
    2. 检查英文状态文本（installed/to install）
  Expected Result: 进度条文本为英文
  Evidence: .sisyphus/evidence/task-1-progress-bar-en.txt
  ```

  **Commit**: YES
  - Message: `feat: 安装进度条显示`
  - Files: `src/quickstart.sh`, `src/lang/*.sh`
  - Pre-commit: `bash scripts/build.sh`

---

- [ ] 2. 安装耗时统计

  **What to do**:

  **2.1 添加 LANG 变量到所有 10 个语言文件**:
  - `LANG_TIME_SECONDS` — 秒（zh: "秒" / en: "s"）
  - `LANG_TIME_TOTAL` — 总耗时（zh: "总耗时" / en: "Total time"）
  - `LANG_TIME_INSTALL_SUMMARY` — 安装摘要（zh: "安装摘要" / en: "Installation Summary"）

  **2.2 修改安装循环，记录每个软件的耗时**:
  在安装每个软件前后用 `date +%s` 记录时间戳：
  ```bash
  local start_time=$(date +%s)
  if install_software "$CONFIG_FILE" "$os" "$sw"; then
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    printf "\r  %s %d/%d %s - %s (%ds)  \n" "$bar" "$current" "$total" "$sw_name" "$LANG_INSTALL_SUCCESS" "$elapsed"
  fi
  ```

  **2.3 安装结束后显示总耗时摘要**:
  ```bash
  local total_end=$(date +%s)
  local total_elapsed=$((total_end - install_start_time))
  echo ""
  log_info "$LANG_TIME_INSTALL_SUMMARY: ${#to_install[@]} $LANG_TOTAL_INSTALLED, $total_elapsed$LANG_TIME_SECONDS"
  ```

  **2.4 进度条行尾添加耗时**:
  Task 1 的进度条行尾追加耗时显示：
  ```
  ██████████░░░░░░░░░░ 4/8 Firefox - 安装完成 (3s)
  ```

  **Must NOT do**:
  - 不使用 `time` 命令（输出格式不统一）
  - 不使用 `$SECONDS`（bash 3.2 中可能不可靠）
  - 用 `date +%s` 作为唯一计时方案

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []
  - 原因: 需要在 Task 1 的进度条基础上修改，同时更新 10 个语言文件

  **Parallelization**:
  - **Can Run In Parallel**: NO（依赖 Task 1 的进度条代码）
  - **Blocks**: Task 4
  - **Blocked By**: Task 1

  **References**:
  - `src/quickstart.sh:1997-2008` — 安装循环（Task 1 修改后）
  - `src/lang/en-US.sh:61-67` — LANG_START_INSTALLING 到 LANG_INSTALLATION_COMPLETE
  - `src/lang/zh-CN.sh:61-67` — 同上中文版

  **Acceptance Criteria**:
  - [ ] 每个软件安装完成后显示耗时 `(3s)`
  - [ ] 安装结束显示总耗时
  - [ ] 10 个语言文件均添加了新 LANG 变量
  - [ ] `bash scripts/build.sh` 成功

  **QA Scenarios**:
  ```
  Scenario: 耗时统计显示
  Tool: Bash
  Steps:
    1. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
    2. 检查输出中包含 (Ns) 格式的耗时
    3. 检查输出中包含 "总耗时" 或类似摘要
  Expected Result: 每个软件安装行尾显示耗时，最后显示总耗时
  Evidence: .sisyphus/evidence/task-2-timing.txt
  ```

  **Commit**: YES
  - Message: `feat: 安装耗时统计`
  - Files: `src/quickstart.sh`, `src/lang/*.sh`
  - Pre-commit: `bash scripts/build.sh`

---

- [ ] 4. 安装失败重试提示

  **What to do**:

  **4.1 添加 LANG 变量到所有 10 个语言文件**:
  - `LANG_RETRY_PROMPT` — 重试提示（zh: "是否重试？[Y/n]" / en: "Retry? [Y/n]"）
  - `LANG_RETRYING` — 重试中（zh: "重试中" / en: "Retrying"）
  - `LANG_INSTALL_FAILED_LIST` — 失败列表（zh: "以下软件安装失败" / en: "The following software failed to install"）

  **4.2 修改安装循环，失败时添加重试交互**:
  ```bash
  if install_software "$CONFIG_FILE" "$os" "$sw"; then
    # ... 成功逻辑（同 Task 1/2）
  else
    printf "\r  %s %d/%d %s - %s  \n" "$bar" "$current" "$total" "$sw_name" "$LANG_INSTALL_FAILED"
    # 重试提示
    if [[ "$NON_INTERACTIVE" != "true" && "$AUTO_YES" != "true" ]]; then
      tput cnorm 2>/dev/null || true
      stty echo 2>/dev/null || true
      printf "  %s " "$LANG_RETRY_PROMPT"
      local retry_answer=""
      IFS= read -rsn1 retry_answer < /dev/tty
      echo ""
      if [[ -z "$retry_answer" || "$retry_answer" =~ ^[Yy] ]]; then
        printf "\r  %s %d/%d %s - %s...\033[K" "$bar" "$current" "$total" "$sw_name" "$LANG_RETRYING"
        if install_software "$CONFIG_FILE" "$os" "$sw"; then
          printf "\r  %s %d/%d %s - %s  \n" "$bar" "$current" "$total" "$sw_name" "$LANG_INSTALL_SUCCESS"
          continue
        fi
      fi
    fi
    install_failed+=("$sw_name")
    tput civis 2>/dev/null || true
    stty -echo 2>/dev/null || true
  fi
  ```

  **4.3 修复硬编码中文的失败列表**:
  行 2011 的 `"以下软件安装失败"` 改为 `$LANG_INSTALL_FAILED_LIST`

  **4.4 非交互模式和 -y 模式跳过重试提示**:
  `NON_INTERACTIVE` 或 `AUTO_YES` 为 true 时不提示，直接标记失败

  **Must NOT do**:
  - 不修改 `install_software()` 函数本身
  - 不在非交互模式弹出提示
  - 重试次数限制为 1 次（不无限重试）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []
  - 原因: 需要处理交互逻辑、终端状态切换（civis/cnorm/stty），容易出 bug

  **Parallelization**:
  - **Can Run In Parallel**: NO（依赖 Task 2 的安装循环代码）
  - **Blocks**: None
  - **Blocked By**: Task 2

  **References**:
  - `src/quickstart.sh:1997-2008` — 安装循环（Task 1/2 修改后）
  - `src/quickstart.sh:2011` — 硬编码中文 `"以下软件安装失败"`
  - `src/quickstart.sh:1838-1868` — continue/exit 选择器（交互模式参考）

  **Acceptance Criteria**:
  - [ ] 安装失败时出现重试提示
  - [ ] 输入 Y/y/回车 → 重试一次
  - [ ] 输入 N/n → 跳过，标记失败
  - [ ] `--non-interactive` 和 `-y` 模式不提示
  - [ ] 硬编码中文 "以下软件安装失败" 改为 LANG 变量
  - [ ] 10 个语言文件均添加了新 LANG 变量
  - [ ] `bash scripts/build.sh` 成功

  **QA Scenarios**:
  ```
  Scenario: 非交互模式无重试提示
  Tool: Bash
  Steps:
    1. bash dist/quickstart.sh --dry-run --profile recommended --non-interactive
    2. 检查输出中没有 "Retry" / "重试" 提示
  Expected Result: 直接完成，无交互提示
  Evidence: .sisyphus/evidence/task-4-no-retry-noninteractive.txt

  Scenario: 硬编码中文修复
  Tool: Bash (grep)
  Steps:
    1. grep -n '以下软件安装失败' src/quickstart.sh
  Expected Result: 无匹配（已替换为 LANG 变量）
  Evidence: .sisyphus/evidence/task-4-no-hardcoded-cn.txt
  ```

  **Commit**: YES
  - Message: `feat: 安装失败重试提示`
  - Files: `src/quickstart.sh`, `src/lang/*.sh`
  - Pre-commit: `bash scripts/build.sh`

---

- [ ] 5. 软件分类标签

  **What to do**:

  **5.1 在 profiles.json 中为每个软件添加 `category` 字段**:
  分类列表和图标映射：
  | category | 图标 | 中文 | English |
  |----------|------|------|---------|
  | browser | 🌐 | 浏览器 | Browser |
  | communication | 💬 | 通讯 | Communication |
  | developer | 🛠 | 开发 | Developer |
  | ai | 🤖 | AI | AI |
  | office | 📄 | 办公 | Office |
  | media | 🎬 | 媒体 | Media |
  | terminal | ⌨️ | 终端 | Terminal |
  | database | 🗄️ | 数据库 | Database |
  | security | 🔒 | 安全 | Security |
  | utilities | 🔧 | 工具 | Utilities |
  | macos-tools | 🍎 | macOS工具 | macOS Tools |
  | china-software | 🇨🇳 | 国产软件 | China Software |

  **5.2 添加 LANG 变量到所有 10 个语言文件**:
  - `LANG_CATEGORY_BROWSER` 到 `LANG_CATEGORY_CHINA_SOFTWARE` — 12 个分类名称

  **5.3 在 `quickstart.sh` 中添加 `get_category_icon()` 函数**:
  ```bash
  get_category_icon() {
    local category="$1"
    case "$category" in
      browser) echo "🌐" ;;
      communication) echo "💬" ;;
      developer) echo "🛠" ;;
      ai) echo "🤖" ;;
      office) echo "📄" ;;
      media) echo "🎬" ;;
      terminal) echo "⌨️" ;;
      database) echo "🗄️" ;;
      security) echo "🔒" ;;
      utilities) echo "🔧" ;;
      macos-tools) echo "🍎" ;;
      china-software) echo "🇨🇳" ;;
      *) echo "📦" ;;
    esac
  }
  ```

  **5.4 修改 `show_software_menu()` 的菜单构建逻辑**:
  - `sw_data` 的 jq/python3 提取中添加 `category` 字段
  - 构造 `menu_names` 时在软件名前加分类图标：
  ```
  🌐 Firefox - 开源浏览器
  💬 Telegram - 即时通讯
  ```

  **5.5 修改 `custom_select_software()` 的菜单构建**:
  同样在软件名前添加分类图标

  **5.6 修改 `config/software/*.json`**:
  每个 JSON 文件中的软件条目添加 `"category"` 字段：
  - `browsers.json` → `"category": "browser"`
  - `communication.json` → `"category": "communication"`
  - `developer.json` → `"category": "developer"`
  - `ai.json` → `"category": "ai"`
  - `office.json` → `"category": "office"`
  - `media.json` → `"category": "media"`
  - `terminal.json` → `"category": "terminal"`
  - `database.json` → `"category": "database"`
  - `security.json` → `"category": "security"`
  - `utilities.json` → `"category": "utilities"`
  - `macos-tools.json` → `"category": "macos-tools"`
  - `china-software.json` → `"category": "china-software"`

  **Must NOT do**:
  - 不修改 profiles.json 的 `profiles` 结构
  - 不修改 `includes` 数组
  - 不添加新的 JSON 文件
  - 分类图标只影响显示，不影响安装逻辑

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []
  - 原因: 需要修改 12 个 JSON 配置文件 + 10 个语言文件 + 主脚本，改动量大

  **Parallelization**:
  - **Can Run In Parallel**: YES（与 Task 1-4 无代码冲突，但建议在 Task 0 之后执行）
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: Task 0

  **References**:
  - `config/software/*.json` — 12 个分类软件配置文件
  - `src/quickstart.sh:1349-1358` — sw_data 提取逻辑（需添加 category 字段）
  - `src/quickstart.sh:1376-1379` — menu_names 构建逻辑（需添加图标）
  - `src/quickstart.sh:1579-1586` — custom_select_software 的菜单构建
  - `src/lang/en-US.sh` — 英文语言文件（添加分类名）
  - `src/lang/zh-CN.sh` — 中文语言文件（添加分类名）

  **Acceptance Criteria**:
  - [ ] 所有 12 个 software/*.json 中每个软件有 `category` 字段
  - [ ] `get_category_icon()` 函数已添加
  - [ ] `show_software_menu` 中软件名前显示分类图标
  - [ ] `custom_select_software` 中软件名前显示分类图标
  - [ ] 10 个语言文件均添加了分类 LANG 变量
  - [ ] `bash scripts/build.sh` 成功

  **QA Scenarios**:
  ```
  Scenario: 分类图标显示
  Tool: Bash
  Steps:
    1. bash dist/quickstart.sh --dev --profile recommended --lang zh
    2. 在软件选择菜单中检查每个软件名前有 emoji 图标
  Expected Result: 浏览器软件前有 🌐，通讯软件前有 💬 等
  Evidence: .sisyphus/evidence/task-5-category-icons.txt

  Scenario: JSON 配置校验
  Tool: Bash
  Steps:
    1. python3 -c "import json; json.load(open('config/profiles.json'))"
    2. 检查所有软件条目都有 category 字段
  Expected Result: JSON 解析无错误，所有软件有 category
  Evidence: .sisyphus/evidence/task-5-json-valid.txt
  ```

  **Commit**: YES
  - Message: `feat: 软件分类标签图标`
  - Files: `config/software/*.json`, `src/quickstart.sh`, `src/lang/*.sh`
  - Pre-commit: `bash scripts/build.sh`

---

- [ ] 6. 修复硬编码中文消息

  **What to do**:
  - 行 2011: `"以下软件安装失败: ${install_failed[*]}"` → `"$LANG_INSTALL_FAILED_LIST: ${install_failed[*]}"`
  - 检查是否有其他硬编码中文（grep 中文字符）

  **Must NOT do**:
  - 不修改语言变量名本身（它们用英文命名）

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES（可与 Task 0 一起做）
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `src/quickstart.sh:2011` — 硬编码中文
  - `src/lang/zh-CN.sh` — 需要添加 LANG_INSTALL_FAILED_LIST
  - `src/lang/en-US.sh` — 需要添加 LANG_INSTALL_FAILED_LIST

  **Acceptance Criteria**:
  - [ ] `grep -n '[\x{4e00}-\x{9fff}]' src/quickstart.sh` 结果中无硬编码中文（LANG 变量值除外）

  **QA Scenarios**:
  ```
  Scenario: 无硬编码中文
  Tool: Bash (grep)
  Steps:
    1. grep -Pn '[\x{4e00}-\x{9fff}]' src/quickstart.sh | grep -v '^#' | grep -v 'LANG_'
  Expected Result: 无匹配或仅有注释中的中文
  Evidence: .sisyphus/evidence/task-6-no-hardcoded.txt
  ```

  **Commit**: YES (合并到 Task 4 的 commit 中)
  - Message: 同 Task 4

---

## Final Verification Wave

- [ ] F1. **完整 dry-run 测试**
  用 `--dry-run --profile recommended --lang zh` 和 `--lang en` 分别测试
  验证：进度条、耗时统计、失败重试提示、分类图标均正确显示
  输出: `PASS/FAIL`

---

## Commit Strategy

| 版本 | Commit Message | 包含 Tasks |
|------|---------------|-----------|
| v0.64.0 | `feat: 安装进度条显示` | Task 0, 1, 6 |
| v0.65.0 | `feat: 安装耗时统计` | Task 2 |
| v0.66.0 | `feat: 安装失败重试提示` | Task 4 |
| v0.67.0 | `feat: 软件分类标签图标` | Task 5 |

---

## Success Criteria

### 验证命令
```bash
bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
bash dist/quickstart.sh --dry-run --profile recommended --lang en --non-interactive
bash dist/quickstart.sh --dev --profile recommended --lang zh
```

### 最终检查
- [ ] 所有 "Must Have" 已实现
- [ ] 所有 "Must NOT Have" 未出现
- [ ] 安装进度条正常显示
- [ ] 安装耗时统计正确
- [ ] 失败重试交互正常
- [ ] 软件分类图标正确
- [ ] 无硬编码中文消息

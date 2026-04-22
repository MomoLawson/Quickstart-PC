# 第二梯队功能开发计划

## TL;DR
> **目标**: 实现三个方向 12 个功能：PowerShell 功能对齐(3)、安装体验增强(4)、错误处理完善(3)、基础设施(2)
>
> **交付物**:
> - PS1 视觉进度条（█░ 替代 [XXX%]）
> - PS1 安装耗时统计（单软件+总耗时）
> - PS1 --custom 自定义选择模式（完整 TUI 移植）
> - 网络超时友好提示
> - 权限不足友好提示
> - 安装前磁盘空间检测
> - 断点续装（状态持久化+恢复）
> - 自我更新 --self-update
> - 安装前后钩子脚本（--allow-hooks 选入）
> - 安装分组/批量执行
> - 发布自动化脚本 scripts/release.sh
> - install_software() 错误输出捕获重构
>
> **预估工作量**: XL
> **并行执行**: YES - 6 waves
> **关键路径**: Release工具(#0) → 错误捕获重构(#1) → 网络超时(#5) → 权限提示(#6) → 断点续装(#8) → 自更新(#9)

---

## Context

### 原始需求
用户选择三个方向全部纳入：D(PowerShell对齐) + A(安装体验增强) + B(错误处理完善)

### 代码现状
- Bash `install_software()` 用 `eval "$cmd" 2>/dev/null` 吞掉所有错误输出
- PS1 `Install-Software` 用 `Invoke-Expression $cmd 2>&1 | Out-Null` 同样吞掉输出
- PS1 进度条只有文字百分比 `[XXX%]`，无视觉进度条
- PS1 完全没有安装耗时统计
- PS1 `--custom` 参数声明了但逻辑未实现
- Bash/PS1 的 `--doctor` 有磁盘空间检查，但安装流程不检查
- 网络超时：curl 有 `--connect-timeout`/`--max-time`，但安装命令本身无超时
- 权限：`sudo apt install -y jq 2>/dev/null` 静默失败，无友好提示
- 断点续装、自更新、钩子脚本：完全不存在
- 无发布自动化脚本，手动 push + release

### Metis Review
**识别的风险**:
- PS1 i18n 是内联 switch 块（10个语言块在同一个文件中），每加一个字符串要改10处，极易遗漏 → QA 必须验证10个语言块键值一致性
- `eval "$cmd" 2>/dev/null` 是错误处理功能的前提瓶颈 → 必须先重构错误捕获
- 并行安装会导致 apt/brew/winget 锁冲突 → 改为安装分组/批量
- 无 release 自动化 → 需先创建 scripts/release.sh
- PS1 --custom TUI 移植是最大功能（Bash 110+ 行终端操作代码）

---

## Work Objectives

### 核心目标
完善 Quickstart-PC 的安装体验、错误处理和 PowerShell 功能对齐，使两个脚本达到功能对等

### 具体交付物
- `scripts/release.sh` — 发布自动化脚本
- `install_software()` / `Install-Software` 错误输出捕获重构
- PS1 `Draw-ProgressBar` 函数 + 安装循环进度条
- PS1 安装耗时统计（Stopwatch）
- PS1 `Select-CustomSoftware` 完整 TUI
- 网络超时检测+友好提示（Bash + PS1）
- 权限不足检测+友好提示（Bash + PS1）
- 安装前磁盘空间检测（Bash + PS1）
- 断点续装 state.json + --resume/--no-resume
- --self-update 自更新机制
- --allow-hooks 钩子脚本支持
- 安装分组/批量执行

### Definition of Done
- [ ] `bash scripts/build.sh` 每个功能后都成功
- [ ] 每个功能单独一个版本号提交
- [ ] `dist/quickstart.sh --help` 和 `dist/quickstart.ps1 -?` 均正常
- [ ] 10 个 Bash 语言文件键值数一致
- [ ] 10 个 PS1 语言块键值数一致
- [ ] ShellCheck / PS1 语法检查通过

### Must Have
- 所有新 UI 文本走 LANG 国际化变量
- macOS bash 3.2 兼容（不用 declare -A）
- 方向键同时支持 `[A`/`OA` 格式
- 每个功能完成后单独 build + commit + push + release
- PS1 --custom 用完整 TUI 移植（方向键导航+空格选择）
- 并行安装改为安装分组/批量
- 钩子脚本需 --allow-hooks 选入（安全）

### Must NOT Have (Guardrails)
- 不能实现真正的并行 apt/brew/winget 调用（会锁冲突）
- 不能用 declare -A 关联数组（bash 3.2 不支持）
- 不能在非交互模式弹出提示
- 不能在钩子中默认允许执行任意脚本（必须 --allow-hooks）
- 不能用 `$SECONDS` 计时（bash 3.2 不可靠）
- PS1 --custom 不能用 Out-GridView（仅限 Windows）
- PS1 i18n 不能重构为外部文件（超出当前范围，保持内联）

---

## Verification Strategy

### 测试决策
- **基础设施存在**: YES (GitHub Actions CI: quality.yml)
- **自动化测试**: Tests-after（功能完成后 dry-run + 手动验证）
- **框架**: bash dry-run 模式 + PS1 -WhatIf 模式

### QA 策略
每个任务完成后用以下方式验证：
- Bash: `bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive`
- Bash: `bash dist/quickstart.sh --dry-run --profile recommended --lang en --non-interactive`
- PS1: `pwsh -NoProfile -File dist/quickstart.ps1 -DryRun -Profile recommended -Lang zh`
- i18n 验证: `for f in src/lang/*.sh; do echo "$f: $(grep -c '^LANG_' "$f")"; done`（10个文件计数一致）
- PS1 i18n: 验证 10 个 switch 块键值数一致
- Build: `bash scripts/build.sh` 必须成功
- ShellCheck: CI 自动运行

---

## Execution Strategy

### 并行执行波次

```
Wave 0 (基础设施 - 必须先完成):
├── Task 0: 发布自动化脚本 scripts/release.sh [quick]
└── Task 1: install_software() 错误输出捕获重构 [deep]

Wave 1 (PS1 对齐 - 三个功能可并行):
├── Task 2: PS1 视觉进度条 (depends: 0) [unspecified-high]
├── Task 3: PS1 安装耗时统计 (depends: 0) [unspecified-high]
└── Task 4: PS1 --custom 自定义选择 TUI (depends: 0) [deep]

Wave 2 (错误处理 - #5/#6 依赖 #1 的错误捕获):
├── Task 5: 网络超时友好提示 (depends: 1) [unspecified-high]
├── Task 6: 权限不足友好提示 (depends: 1) [unspecified-high]
└── Task 7: 安装前磁盘空间检测 [unspecified-high]

Wave 3 (安装体验增强 - 依赖 Wave 2 基础):
├── Task 8: 断点续装 (depends: 7) [deep]
├── Task 9: 自我更新 --self-update (depends: 0, 8) [deep]
└── Task 10: 安装前后钩子脚本 (depends: 1) [unspecified-high]

Wave 4 (安装分组):
└── Task 11: 安装分组/批量执行 (depends: 1) [unspecified-high]

Wave FINAL (验证):
├── F1: 计划合规审计 (oracle)
├── F2: 代码质量审查 (unspecified-high)
├── F3: 真实 QA 测试 (unspecified-high)
└── F4: 范围保真检查 (deep)

Critical Path: Task 0 → Task 1 → Task 5 → Task 8 → Task 9
版本计划: v0.69.0 (#0) → v0.70.0 (#1) → v0.71.0 (#2) → v0.72.0 (#3) → v0.73.0 (#4) → v0.74.0 (#5) → v0.75.0 (#6) → v0.76.0 (#7) → v0.77.0 (#8) → v0.78.0 (#9) → v0.79.0 (#10) → v0.80.0 (#11)
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 3 (Wave 1 & 2)
```

### 依赖矩阵
| Task | Depends On | Blocks |
|------|-----------|--------|
| 0 | - | 2, 3, 4, 9 |
| 1 | - | 5, 6, 10, 11 |
| 2 | 0 | - |
| 3 | 0 | - |
| 4 | 0 | - |
| 5 | 1 | - |
| 6 | 1 | - |
| 7 | - | 8 |
| 8 | 7 | 9 |
| 9 | 0, 8 | - |
| 10 | 1 | - |
| 11 | 1 | - |

### Agent Dispatch Summary
- **Wave 0**: 2 — T0 → `quick`, T1 → `deep`
- **Wave 1**: 3 — T2 → `unspecified-high`, T3 → `unspecified-high`, T4 → `deep`
- **Wave 2**: 3 — T5 → `unspecified-high`, T6 → `unspecified-high`, T7 → `unspecified-high`
- **Wave 3**: 3 — T8 → `deep`, T9 → `deep`, T10 → `unspecified-high`
- **Wave 4**: 1 — T11 → `unspecified-high`
- **FINAL**: 4 — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 0. 发布自动化脚本 scripts/release.sh

**What to do**:
- 创建 `scripts/release.sh`，功能：
  1. 读取 `VERSION` 文件当前版本
  2. 接受参数：`major`/`minor`/`patch` 决定版本号递增方式
  3. 更新 `VERSION` 文件
  4. 运行 `bash scripts/build.sh` 确保构建成功
  5. `git add -A && git commit -m "release: v{VERSION}"`
  6. `git tag v{VERSION}`
  7. `git push origin main --tags`（使用代理 `export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897`）
  8. `gh release create v{VERSION} --title "v{VERSION}" --notes "See commit history for changes."` 附带 dist/ 文件
- 脚本需包含错误处理：build 失败则中止，push 失败则回滚 tag

**Must NOT do**:
- 不修改现有 build.sh
- 不修改 CI 配置

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: []
- 原因: 纯 shell 脚本，逻辑简单

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 1 并行）
- **Parallel Group**: Wave 0
- **Blocks**: Tasks 2, 3, 4, 9
- **Blocked By**: None

**References**:
- `scripts/build.sh` — 现有构建脚本，了解 VERSION 文件格式和构建流程
- `VERSION` — 当前版本号文件
- `.github/workflows/quality.yml` — CI 配置，了解现有验证流程
- `https://cli.github.com/` — gh CLI 用法

**Acceptance Criteria**:
- [ ] `scripts/release.sh` 存在且可执行
- [ ] `bash scripts/release.sh minor` 成功执行完整流程（commit + tag + push + release）
- [ ] build 失败时脚本中止不推送

**QA Scenarios**:
```
Scenario: 发布脚本正常工作
Tool: Bash
Steps:
  1. bash scripts/release.sh minor
  2. gh release list --limit 1
Expected Result: 新版本号出现在 GitHub releases 中
Evidence: .sisyphus/evidence/task-0-release.txt

Scenario: build 失败时中止
Tool: Bash
Steps:
  1. 在 src/quickstart.sh 中插入语法错误
  2. bash scripts/release.sh patch
  3. 检查退出码非0
  4. 撤销语法错误
Expected Result: 脚本退出码非0，无新 tag 创建
Evidence: .sisyphus/evidence/task-0-release-fail.txt
```

**Commit**: YES
- Message: `feat: 发布自动化脚本`
- Files: `scripts/release.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [x] 1. install_software() 错误输出捕获重构

**What to do**:

**1.1 Bash 重构** (`src/quickstart.sh`):
- 将 `eval "$cmd" 2>/dev/null`（行1559）改为捕获错误输出：
```bash
local error_output=""
error_output=$(eval "$cmd" 2>&1) || true
local exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    log_to_file "INFO" "$sw: install success"
    return 0
else
    log_to_file "ERROR" "$sw: install failed (exit $exit_code): $error_output"
    INSTALL_LAST_ERROR="$error_output"
    return 1
fi
```
- 新增全局变量 `INSTALL_LAST_ERROR` 存储最近一次安装错误信息
- `log_to_file` 记录完整错误输出到日志文件（用户不可见，但可排障）

**1.2 PS1 重构** (`src/quickstart.ps1`):
- 将 `Invoke-Expression $cmd 2>&1 | Out-Null`（行1786）改为：
```powershell
$errorOutput = Invoke-Expression $cmd 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Write-Log "$Key $($script:LANG['install_success'])" "SUCCESS"
    $script:INSTALL_LAST_ERROR = ""
    return $true
} else {
    Write-Log "$Key $($script:LANG['install_failed']): $errorOutput" "ERROR"
    $script:INSTALL_LAST_ERROR = $errorOutput
    return $false
}
```
- 新增 `$script:INSTALL_LAST_ERROR` 存储最近错误

**1.3 添加 LANG 变量**（10 个语言文件 + PS1 10 个语言块）:
- `LANG_ERROR_DETAIL` — 错误详情（zh: "错误详情" / en: "Error detail"）

**Must NOT do**:
- 不改变 dry-run 分支的行为
- 不改变 install_software() 的返回值语义（0=成功，1=失败）
- 不在终端直接显示原始错误输出（只在日志中记录，友好提示由 Task 5/6 处理）
- 不修改安装命令本身

**Recommended Agent Profile**:
- **Category**: `deep`
- **Skills**: []
- 原因: 两个脚本的核心函数重构，需仔细处理错误输出捕获，不破坏现有功能

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 0 并行）
- **Parallel Group**: Wave 0
- **Blocks**: Tasks 5, 6, 10, 11
- **Blocked By**: None

**References**:
- `src/quickstart.sh:1550-1565` — `install_software()` 当前实现（eval "$cmd" 2>/dev/null）
- `src/quickstart.sh:1525-1531` — dry-run 分支（不修改）
- `src/quickstart.ps1:1751-1798` — `Install-Software` 当前实现
- `src/quickstart.ps1:1786` — `Invoke-Expression $cmd 2>&1 | Out-Null`
- `src/lang/en-US.sh` — 英文语言文件（添加 LANG_ERROR_DETAIL）
- `src/lang/zh-CN.sh` — 中文语言文件

**Acceptance Criteria**:
- [ ] Bash `install_software()` 不再使用 `2>/dev/null`，错误输出被捕获到日志
- [ ] PS1 `Install-Software` 不再使用 `Out-Null`，错误输出被捕获到日志
- [ ] `INSTALL_LAST_ERROR` / `$script:INSTALL_LAST_ERROR` 变量可用
- [ ] `bash scripts/build.sh` 成功
- [ ] dry-run 模式行为不变
- [ ] 10 个语言文件 + PS1 10 个语言块新增键一致

**QA Scenarios**:
```
Scenario: 错误输出被捕获到日志
Tool: Bash
Steps:
  1. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
  2. 检查日志文件中包含 "ERROR" 级别的记录
Expected Result: 日志文件中有安装失败的错误详情
Evidence: .sisyphus/evidence/task-1-error-capture.txt

Scenario: dry-run 模式不受影响
Tool: Bash
Steps:
  1. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
  2. 检查输出与重构前一致
Expected Result: dry-run 输出格式不变
Evidence: .sisyphus/evidence/task-1-dryrun.txt

Scenario: i18n 一致性
Tool: Bash
Steps:
  1. for f in src/lang/*.sh; do echo "$f: $(grep -c '^LANG_' "$f")"; done
  2. 所有文件计数一致
Expected Result: 10 个文件 LANG_ 变量计数相同
Evidence: .sisyphus/evidence/task-1-i18n.txt
```

**Commit**: YES
- Message: `refactor: install_software() 错误输出捕获`
- Files: `src/quickstart.sh`, `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [x] 2. PS1 视觉进度条

**What to do**:

**2.1 添加 PS1 `Draw-ProgressBar` 函数**:
```powershell
function Draw-ProgressBar {
    param([int]$Current, [int]$Total, [int]$Width = 20)
    $filled = if ($Total -gt 0) { [math]::Floor($Current * $Width / $Total) } else { 0 }
    $empty = $Width - $filled
    $bar = ("█" * $filled) + ("░" * $empty)
    return $bar
}
```

**2.2 修改 PS1 安装循环**（行2709-2727）:
- 将 `$percent = [math]::Round(($current * 100) / $total)` + `Write-Host "... [$($percent.ToString("D3"))%] $swName"`
- 替换为：
```powershell
$bar = Draw-ProgressBar -Current $current -Total $total
Write-Host "`r $bar $current/$total $swName - $($h['installing'])" -NoNewline
```
- 安装成功/失败时用 `\r` 覆写到行首

**2.3 修改 PS1 重试循环**（行2817）:
- 同样替换百分比显示为视觉进度条

**2.4 修改 PS1 检测阶段**:
- 参考 Bash 的静默检测 + 一行摘要模式
- 显示 `████░░░░░░░░░░░░░░░░ 3/8 installed, 5 to install`

**Must NOT do**:
- 不修改 Bash 脚本
- 不修改 JSON 配置
- 不改变安装逻辑，只改显示

**Recommended Agent Profile**:
- **Category**: `unspecified-high`
- **Skills**: []
- 原因: PS1 代码修改，需理解 PowerShell 终端输出特性

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 3, 4 并行）
- **Parallel Group**: Wave 1
- **Blocks**: None
- **Blocked By**: Task 0

**References**:
- `src/quickstart.sh:835-848` — Bash `draw_progress_bar()` 函数（移植参考）
- `src/quickstart.sh:2033-2062` — Bash 安装循环进度条用法
- `src/quickstart.ps1:2709-2727` — PS1 当前安装循环
- `src/quickstart.ps1:2817` — PS1 重试循环百分比显示
- `src/quickstart.ps1:2675-2700` — PS1 检测阶段（需改为静默检测+摘要）

**Acceptance Criteria**:
- [ ] `Draw-ProgressBar` 函数已添加
- [ ] 安装循环显示 `██░░ N/M 软件名 - 安装中...`
- [ ] 重试循环也显示视觉进度条
- [ ] 检测阶段显示一行摘要
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: PS1 进度条显示
Tool: Bash (pwsh)
Steps:
  1. pwsh -NoProfile -File dist/quickstart.ps1 -DryRun -Profile recommended -Lang zh
  2. 检查输出包含 █ 和 ░ 字符
Expected Result: 进度显示包含视觉进度条
Evidence: .sisyphus/evidence/task-2-ps1-progressbar.txt

Scenario: 英文模式进度条
Tool: Bash (pwsh)
Steps:
  1. pwsh -NoProfile -File dist/quickstart.ps1 -DryRun -Profile recommended -Lang en
  2. 检查英文状态文本
Expected Result: 进度条文本为英文
Evidence: .sisyphus/evidence/task-2-ps1-progressbar-en.txt
```

**Commit**: YES
- Message: `feat(ps1): 视觉进度条`
- Files: `src/quickstart.ps1`
- Pre-commit: `bash scripts/build.sh`

---

- [x] 3. PS1 安装耗时统计

**What to do**:

**3.1 添加 LANG 变量**（PS1 10 个语言块 + Bash 10 个语言文件同步，如果缺的话）:
- `LANG_TIME_SECONDS` — 秒后缀（zh: "秒" / en: "s"）
- `LANG_TIME_TOTAL` — 总耗时标签（zh: "总耗时" / en: "Total time"）

注意：Bash 已有这些变量（v0.66.0），PS1 需要新增。检查 PS1 中是否已有，如果没有则添加到 10 个 switch 块。

**3.2 修改 PS1 安装循环**（行2709-2727）:
```powershell
$installStartTime = Get-Date
# 在循环内：
$swStart = Get-Date
$result = Install-Software -Path $script:CONFIG_FILE -OS $os -Key $sw
$swEnd = Get-Date
$swElapsed = ($swEnd - $swStart).TotalSeconds
# 显示: "$bar $current/$total $swName - success (${swElapsed}s)"
```

**3.3 安装结束显示总耗时**:
```powershell
$installEndTime = Get-Date
$totalElapsed = ($installEndTime - $installStartTime).TotalSeconds
Write-Host "$($script:LANG['time_total']): $([math]::Round($totalElapsed))$($script:LANG['time_seconds'])"
```

**3.4 重试循环也添加耗时**

**Must NOT do**:
- 不用 `[System.Diagnostics.Stopwatch]`（Get-Date 够用且更简单）
- 不修改 Bash 脚本（已有此功能）

**Recommended Agent Profile**:
- **Category**: `unspecified-high`
- **Skills**: []
- 原因: PS1 代码修改，需在安装循环中插入计时逻辑

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 2, 4 并行）
- **Parallel Group**: Wave 1
- **Blocks**: None
- **Blocked By**: Task 0

**References**:
- `src/quickstart.sh:2042-2058` — Bash 安装耗时统计实现（移植参考）
- `src/quickstart.ps1:2709-2727` — PS1 安装循环（需插入计时）
- `src/quickstart.ps1:138-1066` — PS1 语言块（需添加 time_seconds, time_total）

**Acceptance Criteria**:
- [ ] PS1 每个软件安装完成后显示耗时 `(Ns)`
- [ ] PS1 安装结束显示总耗时
- [ ] PS1 重试循环也显示耗时
- [ ] PS1 10 个语言块新增 time_seconds, time_total
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: PS1 耗时统计显示
Tool: Bash (pwsh)
Steps:
  1. pwsh -NoProfile -File dist/quickstart.ps1 -DryRun -Profile recommended -Lang zh
  2. 检查输出中包含耗时数字
Expected Result: 每个软件安装行尾显示耗时，最后显示总耗时
Evidence: .sisyphus/evidence/task-3-ps1-timing.txt

Scenario: PS1 i18n 一致性
Tool: Bash
Steps:
  1. 检查 PS1 中 10 个语言块的 time_seconds 和 time_total 键都存在
Expected Result: 10 个块都有新增键
Evidence: .sisyphus/evidence/task-3-ps1-i18n.txt
```

**Commit**: YES
- Message: `feat(ps1): 安装耗时统计`
- Files: `src/quickstart.ps1`
- Pre-commit: `bash scripts/build.sh`

---

- [x] 4. PS1 --custom 自定义选择 TUI

**What to do**:

**4.1 添加 LANG 变量**（PS1 10 个语言块 + Bash 10 个语言文件同步）:
- `LANG_CUSTOM_TITLE` — 自定义选择标题（zh: "自定义选择软件" / en: "Custom Software Selection"）
- `LANG_CUSTOM_SPACE_TOGGLE` — 空格切换提示（zh: "空格: 切换选择" / en: "Space: toggle"）
- `LANG_CUSTOM_ENTER_CONFIRM` — 回车确认提示（zh: "回车: 确认" / en: "Enter: confirm"）
- `LANG_CUSTOM_A_SELECT_ALL` — A 全选提示（zh: "A: 全选/全不选" / en: "A: select/deselect all"）
- `LANG_CUSTOM_SELECTED` — 已选择计数（zh: "已选择 %d/%d" / en: "Selected %d/%d"）

**4.2 实现 PS1 `Select-CustomSoftware` 函数**:
- 移植 Bash 的 `custom_select_software()`（行1569-1680）的完整 TUI 逻辑
- 使用 `[Console]::ReadKey()` 读取方向键（需兼容 Windows Terminal + PowerShell 7）
- 方向键导航：上/下移动光标
- 空格键：切换选择状态
- A 键：全选/全不选
- 回车键：确认选择
- 屏幕重绘：`[Console]::SetCursorPosition()` + `Write-Host`
- 显示格式：`[✓] 🌐 Firefox - 开源浏览器` / `[ ] 🌐 Firefox - 开源浏览器`

**4.3 在 PS1 Main 函数中接入 --custom 分支**:
- 在行 2570-2582 的 profile 选择流程中添加 `$custom` 检测
- 当 `$custom` 为 true 时调用 `Select-CustomSoftware` 获取选择列表

**Must NOT do**:
- 不用 Out-GridView（用户选了完整 TUI 移植）
- 不用简单数字菜单（PromptForChoice）
- 不修改 Bash 的 custom_select_software()

**Recommended Agent Profile**:
- **Category**: `deep`
- **Skills**: []
- 原因: 最大功能——完整 TUI 子系统移植，涉及终端操作、键盘输入、屏幕重绘

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 2, 3 并行）
- **Parallel Group**: Wave 1
- **Blocks**: None
- **Blocked By**: Task 0

**References**:
- `src/quickstart.sh:1569-1680` — Bash `custom_select_software()` 完整 TUI 实现（移植源）
- `src/quickstart.sh:1820-1834` — Bash 中 CUSTOM_MODE 的接入逻辑
- `src/quickstart.ps1:17` — `$custom` 参数声明
- `src/quickstart.ps1:2570-2582` — PS1 profile 选择流程（需添加 custom 分支）
- `src/quickstart.ps1:1535-1640` — PS1 现有的 `Show-SoftwareMenu` 函数（参考图标显示模式）
- `src/quickstart.ps1:138-1066` — PS1 语言块

**Acceptance Criteria**:
- [ ] `Select-CustomSoftware` 函数已实现
- [ ] 方向键上下导航正常
- [ ] 空格键切换选择状态
- [ ] A 键全选/全不选
- [ ] 回车键确认选择
- [ ] 安装循环使用自定义选择结果
- [ ] PS1 10 个语言块新增 5 个键一致
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: PS1 --custom 模式交互
Tool: Bash (pwsh + 交互测试)
Steps:
  1. pwsh -NoProfile -File dist/quickstart.ps1 -Custom -Profile recommended -Lang zh
  2. 用方向键导航，空格选择，回车确认
Expected Result: TUI 显示软件列表，可选择后开始安装
Evidence: .sisyphus/evidence/task-4-ps1-custom.txt

Scenario: --custom 与 --dry-run 组合
Tool: Bash (pwsh)
Steps:
  1. pwsh -NoProfile -File dist/quickstart.ps1 -Custom -DryRun -Profile recommended -Lang zh
Expected Result: 选择后 dry-run 模拟安装
Evidence: .sisyphus/evidence/task-4-ps1-custom-dryrun.txt
```

**Commit**: YES
- Message: `feat(ps1): 自定义选择模式 --custom`
- Files: `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [ ] 5. 网络超时友好提示

**What to do**:

**5.1 添加 LANG 变量**（Bash 10 个 + PS1 10 个语言块）:
- `LANG_NETWORK_TIMEOUT` — 网络超时提示（zh: "网络连接超时，请检查网络设置" / en: "Network connection timed out, please check your network"）
- `LANG_NETWORK_ERROR` — 网络错误提示（zh: "网络错误: %s" / en: "Network error: %s"）
- `LANG_CHECK_NETWORK` — 检查网络建议（zh: "建议: 检查网络连接或设置代理" / en: "Suggestion: Check network connection or set proxy"）

**5.2 Bash 实现** (`src/quickstart.sh`):
- 在 `install_software()` 中，利用 Task 1 的 `INSTALL_LAST_ERROR` 分类错误：
```bash
if [[ $exit_code -ne 0 ]]; then
    # 分类错误
    case "$INSTALL_LAST_ERROR" in
        *"timed out"*|*"timeout"*|*"Connection timed"*|*"could not resolve"*)
            log_warn "$LANG_NETWORK_TIMEOUT"
            log_warn "$LANG_CHECK_NETWORK"
            ;;
        *"Connection refused"*|*"Network is unreachable"*)
            log_warn "$LANG_NETWORK_ERROR: $(echo "$INSTALL_LAST_ERROR" | head -1)"
            ;;
        *)
            log_warn "$LANG_INSTALL_FAILED: $sw"
            ;;
    esac
fi
```
- 在安装失败汇总中，对网络相关失败给出专门建议

**5.3 PS1 实现** (`src/quickstart.ps1`):
- 在 `Install-Software` 的 catch 块中，根据 `$script:INSTALL_LAST_ERROR` 分类：
```powershell
if ($script:INSTALL_LAST_ERROR -match "timed out|timeout|Connection timed|could not resolve") {
    Write-Host $script:LANG["network_timeout"] -ForegroundColor Yellow
    Write-Host $script:LANG["check_network"] -ForegroundColor Yellow
}
```

**5.4 在安装失败汇总中按错误类型分组显示**:
- 网络超时类失败 → 显示网络建议
- 权限类失败 → 显示权限建议（Task 6 处理）
- 其他失败 → 通用提示

**Must NOT do**:
- 不对 curl 命令本身添加超时（已有 --connect-timeout）
- 不添加自动重试逻辑（重试已有单独机制）
- 不在非交互模式弹出提示（只写日志）

**Recommended Agent Profile**:
- **Category**: `unspecified-high`
- **Skills**: []
- 原因: 需要两个脚本同时修改，错误分类逻辑需仔细设计

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 6, 7 并行）
- **Parallel Group**: Wave 2
- **Blocks**: None
- **Blocked By**: Task 1（需要 INSTALL_LAST_ERROR 变量）

**References**:
- `src/quickstart.sh:1550-1565` — `install_software()` 重构后的错误捕获（Task 1 产出）
- `src/quickstart.ps1:1751-1798` — `Install-Software` 重构后（Task 1 产出）
- `src/quickstart.sh:62` — curl 超时参数参考
- `src/quickstart.sh:621-630` — `--doctor` 网络检查逻辑参考

**Acceptance Criteria**:
- [ ] 网络超时时显示友好提示而非静默失败
- [ ] 提示包含解决建议
- [ ] 安装失败汇总按错误类型分组
- [ ] 20 个语言位置（10 .sh + 10 PS1 块）新增键一致
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: 网络超时友好提示（Bash）
Tool: Bash
Steps:
  1. 在 /etc/hosts 中临时屏蔽一个下载域名
  2. bash dist/quickstart.sh --profile recommended --lang zh --non-interactive
  3. 检查输出中包含 "网络" 相关提示
  4. 恢复 /etc/hosts
Expected Result: 显示网络超时友好提示和建议
Evidence: .sisyphus/evidence/task-5-network-timeout.txt

Scenario: PS1 网络错误提示
Tool: Bash (pwsh)
Steps:
  1. pwsh -NoProfile -File dist/quickstart.ps1 -DryRun -Profile recommended -Lang en
  2. 检查网络错误处理代码存在
Expected Result: PS1 中有网络错误分类逻辑
Evidence: .sisyphus/evidence/task-5-ps1-network.txt
```

**Commit**: YES
- Message: `feat: 网络超时友好提示`
- Files: `src/quickstart.sh`, `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [ ] 6. 权限不足友好提示

**What to do**:

**6.1 添加 LANG 变量**（Bash 10 个 + PS1 10 个语言块）:
- `LANG_PERMISSION_DENIED` — 权限不足提示（zh: "权限不足: %s" / en: "Permission denied: %s"）
- `LANG_PERMISSION_SUGGESTION` — 权限建议（zh: "建议: 使用 sudo 运行或联系管理员" / en: "Suggestion: Run with sudo or contact your administrator"）
- `LANG_NEED_SUDO` — 需要 sudo（zh: "此操作需要管理员权限" / en: "This operation requires administrator privileges"）
- `LANG_NEED_ADMIN` — 需要管理员（PS1 Windows 用）（zh: "请以管理员身份运行 PowerShell" / en: "Please run PowerShell as Administrator"）

**6.2 Bash 实现**:
- 在 `install_software()` 错误分类中添加权限检测：
```bash
case "$INSTALL_LAST_ERROR" in
    *"Permission denied"*|*"not allowed"*|*"Operation not permitted"*|*"EACCES"*)
        log_warn "$LANG_PERMISSION_DENIED: $sw"
        log_warn "$LANG_PERMISSION_SUGGESTION"
        ;;
esac
```
- 在 `sudo apt install` 之前检测 sudo 是否可用：
```bash
if ! command -v sudo &>/dev/null; then
    log_warn "$LANG_NEED_SUDO"
fi
```

**6.3 PS1 实现**:
- 检测 `Invoke-Expression` 错误中是否包含 "Access denied" / "UnauthorizedAccessException"
- Windows 特有：检测是否以管理员身份运行：
```powershell
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host $script:LANG["need_admin"] -ForegroundColor Yellow }
```

**6.4 安装失败汇总中权限类失败单独分组显示建议**

**Must NOT do**:
- 不自动提权（不自动 sudo/runas）
- 不在已获取权限时显示提示
- 不修改 --doctor 的权限检查（只参考逻辑）

**Recommended Agent Profile**:
- **Category**: `unspecified-high`
- **Skills**: []
- 原因: 跨两个脚本，需处理 Unix/Windows 不同权限模型

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 5, 7 并行）
- **Parallel Group**: Wave 2
- **Blocks**: None
- **Blocked By**: Task 1

**References**:
- `src/quickstart.sh:312,352,424,455,502,716,878` — sudo apt install 调用点
- `src/quickstart.ps1:1751-1798` — Install-Software（需添加权限检测）
- `src/quickstart.sh:621-630` — --doctor 权限相关检查参考

**Acceptance Criteria**:
- [ ] 权限不足时显示友好提示和解决建议
- [ ] Windows PS1 检测管理员身份
- [ ] Unix Bash 检测 sudo 可用性
- [ ] 安装失败汇总按错误类型分组
- [ ] 20 个语言位置新增键一致
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: 权限不足提示（Bash）
Tool: Bash
Steps:
  1. grep -n 'Permission denied\|LANG_PERMISSION' src/quickstart.sh
  2. 确认权限检测和提示代码存在
Expected Result: 代码中包含权限错误分类和友好提示
Evidence: .sisyphus/evidence/task-6-permission-check.txt

Scenario: Windows 管理员检测（PS1）
Tool: Bash
Steps:
  1. grep -n 'IsInRole\|need_admin\|Administrator' src/quickstart.ps1
Expected Result: PS1 中包含管理员身份检测逻辑
Evidence: .sisyphus/evidence/task-6-ps1-admin.txt
```

**Commit**: YES
- Message: `feat: 权限不足友好提示`
- Files: `src/quickstart.sh`, `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [ ] 7. 安装前磁盘空间检测

**What to do**:

**7.1 添加 LANG 变量**（Bash 10 个 + PS1 10 个语言块）:
- `LANG_DISK_SPACE_LOW` — 磁盘空间不足（zh: "磁盘空间不足: 可用 %s，建议至少 %s" / en: "Low disk space: %s available, at least %s recommended"）
- `LANG_DISK_SPACE_WARNING` — 磁盘空间警告（zh: "⚠ 磁盘空间较低，安装可能失败" / en: "⚠ Low disk space, installation may fail"）
- `LANG_DISK_CHECKING` — 检查磁盘（zh: "检查磁盘空间..." / en: "Checking disk space..."）

**7.2 Bash 实现**:
- 提取 `--doctor` 中的磁盘检测逻辑为独立函数 `check_disk_space()`:
```bash
check_disk_space() {
    local min_gb=${1:-5}  # 默认至少5GB
    local available_gb
    if [[ "$OS_TYPE" == "darwin" ]]; then
        available_gb=$(df -g / | awk 'NR==2 {print $4}')
    else
        available_gb=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    fi
    if [[ $available_gb -lt $min_gb ]]; then
        log_warn "$LANG_DISK_SPACE_LOW" "$available_gb" "${min_gb}"
        return 1
    fi
    return 0
}
```
- 在 `main()` 安装循环之前调用 `check_disk_space`
- 空间不足时显示警告但允许继续（非致命），`--non-interactive` 模式自动跳过

**7.3 PS1 实现**:
- 同样从 `Show-Doctor` 提取磁盘检测为 `Test-DiskSpace`:
```powershell
function Test-DiskSpace {
    param([int]$MinGB = 5)
    $drive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
    if ($drive) {
        $availableGB = [math]::Round($drive.Free / 1GB)
        if ($availableGB -lt $MinGB) {
            Write-Host "$($script:LANG['disk_space_low'])" -ForegroundColor Yellow
            return $false
        }
    }
    return $true
}
```

**Must NOT do**:
- 不把磁盘检测设为致命错误（只警告，允许继续）
- 不在非交互模式中止安装
- 不删除 --doctor 中的磁盘检测代码（保留原有功能）

**Recommended Agent Profile**:
- **Category**: `unspecified-high`
- **Skills**: []
- 原因: 两个脚本 + 逻辑提取，中等复杂度

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 5, 6 并行）
- **Parallel Group**: Wave 2
- **Blocks**: Task 8
- **Blocked By**: None

**References**:
- `src/quickstart.sh:639-658` — Bash `--doctor` 磁盘检测逻辑（提取源）
- `src/quickstart.ps1:2243-2258` — PS1 `Show-Doctor` 磁盘检测逻辑（提取源）
- `src/quickstart.sh:2029-2095` — Bash main() 安装循环前（插入检测调用点）

**Acceptance Criteria**:
- [ ] Bash `check_disk_space()` 函数已提取
- [ ] PS1 `Test-DiskSpace` 函数已提取
- [ ] 安装前自动检测磁盘空间
- [ ] 空间不足时显示警告（不中止）
- [ ] --doctor 磁盘检测仍正常工作
- [ ] 20 个语言位置新增键一致
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: 磁盘空间检测（Bash）
Tool: Bash
Steps:
  1. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
  2. 检查输出中包含磁盘空间信息
Expected Result: 安装前显示磁盘空间检测
Evidence: .sisyphus/evidence/task-7-disk-check.txt

Scenario: --doctor 磁盘检测仍正常
Tool: Bash
Steps:
  1. bash dist/quickstart.sh --doctor --lang zh
  2. 检查磁盘空间信息正常显示
Expected Result: doctor 模式磁盘检测不受影响
Evidence: .sisyphus/evidence/task-7-doctor-disk.txt
```

**Commit**: YES
- Message: `feat: 安装前磁盘空间检测`
- Files: `src/quickstart.sh`, `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [ ] 8. 断点续装

**What to do**:

**8.1 添加 LANG 变量**（Bash 10 个 + PS1 10 个语言块）:
- `LANG_RESUME_FOUND` — 发现未完成安装（zh: "发现未完成的安装，是否继续？" / en: "Incomplete installation found. Resume?"）
- `LANG_RESUMING` — 正在恢复（zh: "从上次中断处继续安装..." / en: "Resuming from last checkpoint..."）
- `LANG_CHECKPOINT_SAVED` — 进度已保存（zh: "安装进度已保存" / en: "Installation progress saved"）
- `LANG_INSTALL_COMPLETE_STATE` — 安装完成（状态文件清理）（zh: "安装完成，清理临时文件" / en: "Installation complete, cleaning up"）

**8.2 Bash 实现**:

状态文件: `~/.config/quickstart-pc/state.json`（用 jq 读写，不用 declare -A）
```json
{
  "profile": "recommended",
  "total": 8,
  "installed": ["firefox", "chrome"],
  "failed": [],
  "remaining": ["telegram", "vscode", "..."],
  "timestamp": "2026-04-22T10:30:00+08:00"
}
```

核心函数:
```bash
save_install_state() {
    # 保存当前安装进度到 state.json
    local state_file="$HOME/.config/quickstart-pc/state.json"
    mkdir -p "$(dirname "$state_file")"
    # 用 jq 构建 JSON（不用关联数组）
    jq -n \
        --arg profile "$SELECTED_PROFILE" \
        --argjson total "${#to_install[@]}" \
        --arg remaining "$remaining_json" \
        --arg installed "$installed_json" \
        --arg failed "$failed_json" \
        --arg ts "$(date -Iseconds)" \
        '{profile: $profile, total: $total, remaining: ($remaining | fromjson), installed: ($installed | fromjson), failed: ($failed | fromjson), timestamp: $ts}' \
        > "$state_file"
}

load_install_state() {
    # 读取 state.json，返回 remaining 列表
    local state_file="$HOME/.config/quickstart-pc/state.json"
    if [[ -f "$state_file" ]]; then
        local remaining
        remaining=$(jq -r '.remaining[]' "$state_file")
        echo "$remaining"
    fi
}

clear_install_state() {
    rm -f "$HOME/.config/quickstart-pc/state.json"
}
```

**8.3 安装流程集成**:
- `main()` 开始时检测 state.json 是否存在
- 如果存在 + 非 `--no-resume` 模式 → 提示 "是否继续上次安装？[Y/n]"
- `--resume` 强制恢复 / `--no-resume` 跳过恢复
- 每个软件安装后调用 `save_install_state()` 更新进度
- 全部安装完成后 `clear_install_state()`
- 信号处理：捕获 SIGINT (Ctrl+C) 时保存状态再退出

**8.4 PS1 实现**:
- 状态文件: `$env:USERPROFILE\.config\quickstart-pc\state.json`
- 用 `ConvertFrom-Json` / `ConvertTo-Json` 读写
- 同样的 resume/no-resume 逻辑
- 用 `[Console]::TreatControlCAsInput` 捕获 Ctrl+C

**8.5 添加命令行参数**:
- Bash: `--resume` / `--no-resume`
- PS1: `-Resume` / `-NoResume`

**Must NOT do**:
- 不用 declare -A 关联数组（bash 3.2 不支持）
- 不在非交互模式自动恢复（除非指定 --resume）
- 不保存敏感信息到 state.json
- 不把 state.json 提交到 git

**Recommended Agent Profile**:
- **Category**: `deep`
- **Skills**: []
- 原因: 需要两个脚本同时实现状态持久化+恢复+信号处理，逻辑复杂

**Parallelization**:
- **Can Run In Parallel**: NO（依赖 Task 7 的磁盘检测函数作为前置检查）
- **Parallel Group**: Wave 3
- **Blocks**: Task 9
- **Blocked By**: Task 7

**References**:
- `src/quickstart.sh:2029-2095` — Bash main() 安装循环（需插入状态保存/恢复）
- `src/quickstart.ps1:2709-2727` — PS1 安装循环（同上）
- `src/quickstart.sh:1550-1565` — install_software()（每步后保存状态）
- `src/quickstart.sh:183-225` — Bash 命令行参数解析（需添加 --resume/--no-resume）
- `src/quickstart.ps1:1-40` — PS1 参数声明（需添加 -Resume/-NoResume）

**Acceptance Criteria**:
- [ ] 安装中断后重新运行能检测到未完成状态
- [ ] 提示是否继续（自动检测模式）
- [ ] `--resume` 强制恢复 / `--no-resume` 跳过
- [ ] 每个软件安装后状态文件更新
- [ ] 全部完成后状态文件清理
- [ ] Ctrl+C 时保存状态再退出
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: 断点续装检测
Tool: Bash
Steps:
  1. 创建模拟 state.json 到 ~/.config/quickstart-pc/
  2. bash dist/quickstart.sh --profile recommended --lang zh
  3. 检查是否出现 "发现未完成的安装" 提示
  4. 清理 state.json
Expected Result: 显示恢复安装提示
Evidence: .sisyphus/evidence/task-8-resume-detect.txt

Scenario: --no-resume 跳过恢复
Tool: Bash
Steps:
  1. 创建模拟 state.json
  2. bash dist/quickstart.sh --profile recommended --lang zh --no-resume
  3. 检查无恢复提示
  4. 清理 state.json
Expected Result: 直接正常安装，不提示恢复
Evidence: .sisyphus/evidence/task-8-no-resume.txt

Scenario: 安装完成后状态清理
Tool: Bash
Steps:
  1. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
  2. 检查 ~/.config/quickstart-pc/state.json 不存在
Expected Result: 安装完成后无残留 state 文件
Evidence: .sisyphus/evidence/task-8-state-cleanup.txt
```

**Commit**: YES
- Message: `feat: 断点续装`
- Files: `src/quickstart.sh`, `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [ ] 9. 自我更新 --self-update

**What to do**:

**9.1 添加 LANG 变量**（Bash 10 个 + PS1 10 个语言块）:
- `LANG_UPDATE_CHECKING` — 检查更新中（zh: "检查更新..." / en: "Checking for updates..."）
- `LANG_UPDATE_AVAILABLE` — 有新版本（zh: "发现新版本: %s (当前: %s)" / en: "New version available: %s (current: %s)"）
- `LANG_UPDATE_LATEST` — 已是最新（zh: "已是最新版本" / en: "Already on the latest version"）
- `LANG_UPDATE_DOWNLOADING` — 下载更新中（zh: "下载更新..." / en: "Downloading update..."）
- `LANG_UPDATE_SUCCESS` — 更新成功（zh: "更新成功！请重新运行脚本" / en: "Update successful! Please restart the script"）
- `LANG_UPDATE_FAILED` — 更新失败（zh: "更新失败: %s" / en: "Update failed: %s"）
- `LANG_UPDATE_PROMPT` — 更新提示（zh: "是否更新到新版本？[Y/n]" / en: "Update to new version? [Y/n]"）

**9.2 版本检查函数**:
- 使用 GitHub Releases API: `https://api.github.com/repos/{owner}/{repo}/releases/latest`
- 比较当前版本（读取 VERSION 文件中的 `__VERSION__` 替换值）与最新 tag
- 版本比较：strip "v" 前缀，用 `sort -V` 比较

**9.3 Bash 实现**:
```bash
self_update() {
    local current_version="$VERSION"
    local latest_version
    latest_version=$(curl -fsSL --connect-timeout 5 --max-time 10 \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/MomoLawson/Quickstart-PC/releases/latest" \
        | jq -r '.tag_name // empty')
    latest_version="${latest_version#v}"  # strip v prefix

    if [[ -z "$latest_version" ]]; then
        log_warn "$LANG_UPDATE_FAILED: GitHub API error"
        return 1
    fi

    if [[ "$current_version" == "$latest_version" ]]; then
        log_info "$LANG_UPDATE_LATEST"
        return 0
    fi

    log_info "$(printf "$LANG_UPDATE_AVAILABLE" "$latest_version" "$current_version")"

    # 交互提示
    if [[ "$NON_INTERACTIVE" != "true" && "$AUTO_YES" != "true" ]]; then
        printf " %s " "$(printf "$LANG_UPDATE_PROMPT")"
        # ... read answer ...
    fi

    # 下载新版本到临时文件 → 原子替换
    local tmpfile
    tmpfile=$(mktemp "/tmp/quickstart-XXXXXXXXXX.sh")
    curl -fsSL --connect-timeout 10 --max-time 60 \
        "https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/v${latest_version}/dist/quickstart.sh" \
        -o "$tmpfile"
    chmod +x "$tmpfile"
    mv -f "$tmpfile" "$(which quickstart.sh 2>/dev/null || echo "$0")"
    log_info "$LANG_UPDATE_SUCCESS"
}
```

**9.4 PS1 实现**:
- 使用 `Invoke-RestMethod` 调用 GitHub API
- 下载用 `Invoke-WebRequest`
- **关键**: Windows 文件锁定问题 → 用子进程替换模式（Scoop 模式）：
  - 生成临时 update.ps1 脚本
  - `Start-Process pwsh -File update.ps1 -Wait`
  - 当前进程退出
  - update.ps1 下载新版本 → 替换 → 清理

**9.5 添加命令行参数**:
- Bash: `--self-update` / `--check-update`（只检查不更新）
- PS1: `-SelfUpdate` / `-CheckUpdate`

**9.6 启动时自动检查更新**（可选，非交互模式下跳过）:
- 在 `main()` 开始时静默检查（缓存结果，每日最多检查一次）
- 有新版本时在安装完成后提示更新

**Must NOT do**:
- 不在非交互模式自动更新（只提示）
- 不在安装过程中更新（安装完成后才更新）
- 不用 git pull 更新（用户可能不是 git clone 安装的）
- 不验证 SHA256（初版不加，后续可加）

**Recommended Agent Profile**:
- **Category**: `deep`
- **Skills**: []
- 原因: 两个脚本+跨平台安全替换+Windows 文件锁+GitHub API，复杂度高

**Parallelization**:
- **Can Run In Parallel**: NO（依赖 Task 0 的 release 工具和 Task 8 的状态管理）
- **Parallel Group**: Wave 3
- **Blocks**: None
- **Blocked By**: Task 0, Task 8

**References**:
- `VERSION` — 版本号文件格式
- `scripts/build.sh` — 构建流程（理解 __VERSION__ 替换）
- `src/quickstart.sh:62` — curl 超时参数参考
- `src/quickstart.ps1:138-1066` — PS1 语言块
- GitHub Releases API: `https://api.github.com/repos/{owner}/{repo}/releases/latest`

**Acceptance Criteria**:
- [ ] `--self-update` 检查 GitHub 最新版本并提示
- [ ] `--check-update` 只检查不更新
- [ ] Bash: 下载+原子替换成功
- [ ] PS1: 子进程替换模式成功
- [ ] 非交互模式不自动更新
- [ ] 版本已是最新时显示提示
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: 版本检查（Bash）
Tool: Bash
Steps:
  1. bash dist/quickstart.sh --check-update --lang zh
  2. 检查输出包含版本检查结果
Expected Result: 显示当前版本和最新版本信息
Evidence: .sisyphus/evidence/task-9-check-update.txt

Scenario: 已是最新版本
Tool: Bash
Steps:
  1. 确保当前版本 >= GitHub 最新版本
  2. bash dist/quickstart.sh --check-update --lang en
Expected Result: 显示 "Already on the latest version"
Evidence: .sisyphus/evidence/task-9-latest-version.txt

Scenario: PS1 更新机制存在
Tool: Bash
Steps:
  1. grep -n 'SelfUpdate\|CheckUpdate\|self_update' src/quickstart.ps1
Expected Result: PS1 中包含自更新参数和逻辑
Evidence: .sisyphus/evidence/task-9-ps1-update.txt
```

**Commit**: YES
- Message: `feat: 自我更新 --self-update`
- Files: `src/quickstart.sh`, `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [ ] 10. 安装前后钩子脚本

**What to do**:

**10.1 添加 LANG 变量**（Bash 10 个 + PS1 10 个语言块）:
- `LANG_HOOK_RUNNING` — 执行钩子（zh: "执行钩子: %s" / en: "Running hook: %s"）
- `LANG_HOOK_SUCCESS` — 钩子成功（zh: "钩子执行完成" / en: "Hook completed"）
- `LANG_HOOK_FAILED` — 钩子失败（zh: "钩子执行失败: %s" / en: "Hook failed: %s"）
- `LANG_HOOKS_DISABLED` — 钩子已禁用（zh: "钩子脚本已禁用，使用 --allow-hooks 启用" / en: "Hooks disabled, use --allow-hooks to enable"）
- `LANG_HOOKS_ENABLED` — 钩子已启用（zh: "钩子脚本已启用" / en: "Hooks enabled"）

**10.2 钩子配置格式**（在 profiles.json 中）:
```json
{
  "hooks": {
    "pre_install": "path/to/pre-script.sh",
    "post_install": "path/to/post-script.sh",
    "pre_software": "path/to/pre-software.sh",
    "post_software": "path/to/post-software.sh"
  }
}
```
- `pre_install`: 整个安装开始前执行一次
- `post_install`: 整个安装完成后执行一次
- `pre_software`: 每个软件安装前执行（环境变量: `$SOFTWARE_KEY`, `$SOFTWARE_NAME`）
- `post_software`: 每个软件安装后执行

**10.3 Bash 实现**:
```bash
run_hook() {
    local hook_type="$1"  # pre_install, post_install, pre_software, post_software
    local hook_script
    hook_script=$(jq -r ".hooks.${hook_type} // empty" "$CONFIG_FILE")

    if [[ -z "$hook_script" ]]; then return 0; fi
    if [[ "$ALLOW_HOOKS" != "true" ]]; then
        log_info "$LANG_HOOKS_DISABLED"
        return 0
    fi

    log_info "$(printf "$LANG_HOOK_RUNNING" "$hook_type")"
    if bash "$hook_script"; then
        log_info "$LANG_HOOK_SUCCESS"
    else
        log_warn "$(printf "$LANG_HOOK_FAILED" "$hook_type")"
        # 钩子失败不中止安装（仅警告）
    fi
}
```

**10.4 PS1 实现**:
```powershell
function Invoke-HookScript {
    param([string]$HookType)
    $hookScript = Get-ProfileField -Path $script:CONFIG_FILE -Key "hooks" -Field $HookType
    if (-not $hookScript) { return }
    if (-not $AllowHooks) {
        Write-Host $script:LANG["hooks_disabled"]
        return
    }
    Write-Host "$($script:LANG['hook_running']) $HookType"
    try {
        & $hookScript
        Write-Host $script:LANG["hook_success"]
    } catch {
        Write-Warning "$($script:LANG['hook_failed']) $HookType"
    }
}
```

**10.5 安全机制**:
- 默认禁用钩子（`ALLOW_HOOKS=false`）
- 需 `--allow-hooks` 参数选入
- 钩子脚本失败不中止主安装流程
- 钩子脚本路径必须在配置文件中声明（不能命令行指定）

**10.6 添加命令行参数**:
- Bash: `--allow-hooks`
- PS1: `-AllowHooks`

**Must NOT do**:
- 不默认启用钩子（安全风险）
- 不允许命令行直接指定钩子脚本路径
- 钩子失败时不中止安装
- 不实现钩子脚本的沙箱/权限限制（超出范围）

**Recommended Agent Profile**:
- **Category**: `unspecified-high`
- **Skills**: []
- 原因: 两个脚本 + 配置扩展 + 安全考量，中等复杂度

**Parallelization**:
- **Can Run In Parallel**: YES（与 Task 8, 9 并行，前提是 Task 1 已完成）
- **Parallel Group**: Wave 3
- **Blocks**: None
- **Blocked By**: Task 1

**References**:
- `src/quickstart.sh:2029-2095` — Bash main() 安装循环（需插入钩子调用点）
- `src/quickstart.ps1:2709-2727` — PS1 安装循环（同上）
- `config/profiles.json` — profiles 配置（需添加 hooks 字段示例）
- `src/quickstart.sh:183-225` — Bash 参数解析（需添加 --allow-hooks）
- `src/quickstart.ps1:1-40` — PS1 参数声明（需添加 -AllowHooks）

**Acceptance Criteria**:
- [ ] 钩子脚本可配置（profiles.json hooks 字段）
- [ ] 默认禁用，需 --allow-hooks 启用
- [ ] pre_install/post_install 钩子在安装前后执行
- [ ] pre_software/post_software 钩子在每个软件前后执行
- [ ] 钩子失败不中止安装
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: 钩子默认禁用
Tool: Bash
Steps:
  1. 在 profiles.json 中添加 hooks 字段
  2. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
  3. 检查输出中无 "执行钩子" 字样
Expected Result: 钩子不执行，显示禁用提示
Evidence: .sisyphus/evidence/task-10-hooks-disabled.txt

Scenario: --allow-hooks 启用钩子
Tool: Bash
Steps:
  1. 创建测试钩子脚本 /tmp/test-hook.sh (echo "hook executed")
  2. 在 profiles.json 中添加 hooks.pre_install = "/tmp/test-hook.sh"
  3. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --allow-hooks --non-interactive
  4. 检查输出包含 "hook executed"
  5. 清理测试文件和 profiles.json
Expected Result: 钩子脚本被执行
Evidence: .sisyphus/evidence/task-10-hooks-enabled.txt
```

**Commit**: YES
- Message: `feat: 安装前后钩子脚本`
- Files: `src/quickstart.sh`, `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

- [ ] 11. 安装分组/批量执行

**What to do**:

**11.1 添加 LANG 变量**（Bash 10 个 + PS1 10 个语言块）:
- `LANG_BATCH_INSTALLING` — 批量安装中（zh: "批量安装 %d 个软件..." / en: "Batch installing %d packages..."）
- `LANG_BATCH_SUCCESS` — 批量安装成功（zh: "批量安装完成: %d/%d 成功" / en: "Batch install complete: %d/%d succeeded"）
- `LANG_BATCH_FAILED` — 批量安装部分失败（zh: "批量安装部分失败: %d 个失败" / en: "Batch install partially failed: %d failed"）

**11.2 Bash 实现**:

核心思路：将同包管理器的软件合并为一条命令执行，而非逐个调用。

```bash
install_batch() {
    local manager="$1"  # apt, brew, winget, etc.
    shift
    local packages=("$@")
    local cmd=""

    case "$manager" in
        apt)    cmd="sudo apt install -y ${packages[*]}" ;;
        brew)   cmd="brew install ${packages[*]}" ;;
        winget) cmd="winget install -e --id ${packages[*]}" ;;
        npm)    cmd="npm install -g ${packages[*]}" ;;
        *)      # 不支持的包管理器回退到逐个安装
                for pkg in "${packages[@]}"; do
                    install_software "$CONFIG_FILE" "$os" "$pkg"
                done
                return ;;
    esac

    log_info "$(printf "$LANG_BATCH_INSTALLING" "${#packages[@]}")"
    local error_output
    error_output=$(eval "$cmd" 2>&1) || true
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_info "$(printf "$LANG_BATCH_SUCCESS" "${#packages[@]}" "${#packages[@]}")"
    else
        log_warn "$(printf "$LANG_BATCH_FAILED" "?")"
        # 回退：逐个安装以精确定位失败软件
        for pkg in "${packages[@]}"; do
            install_software "$CONFIG_FILE" "$os" "$pkg"
        done
    fi
}
```

**11.3 安装循环重构**:
- 检测阶段后，按包管理器分组软件
- 优先批量安装同组软件
- 批量失败时回退逐个安装

**11.4 PS1 实现**:
- 同样的分组逻辑
- 用 `Invoke-Expression` 执行批量命令
- 失败回退逐个 `Install-Software`

**11.5 兼容性考虑**:
- `apt install -y git curl wget` → 一次安装多个（最常见提速场景）
- `brew install git curl wget` → brew 本身会并行处理
- `winget install --id Git.Git --id Mozilla.Firefox` → 可能不支持批量，回退逐个
- `npm install -g typescript prettier eslint` → 支持

**Must NOT do**:
- 不实现真正的并行执行（包管理器有全局锁）
- 不对批量命令添加超时（单软件超时已在 Task 5 处理）
- 不改变 --dry-run 的模拟输出格式（仍逐个显示）
- 不修改 config/software/*.json（包管理器信息已存在于 install 命令中）

**Recommended Agent Profile**:
- **Category**: `unspecified-high`
- **Skills**: []
- 原因: 需重构安装循环逻辑，分组+批量+回退，两个脚本

**Parallelization**:
- **Can Run In Parallel**: NO（Wave 4 独立执行，依赖 Task 1 的错误捕获）
- **Parallel Group**: Wave 4
- **Blocks**: None
- **Blocked By**: Task 1

**References**:
- `src/quickstart.sh:2029-2095` — Bash main() 安装循环（需重构为分组模式）
- `src/quickstart.ps1:2709-2727` — PS1 安装循环（同上）
- `src/quickstart.sh:1550-1565` — `install_software()`（回退逐个安装时调用）
- `config/software/*.json` — 软件配置（了解 install 命令格式，判断哪些可批量）

**Acceptance Criteria**:
- [ ] 同包管理器的软件合并为一条命令安装
- [ ] 批量安装失败时自动回退逐个安装
- [ ] 进度条正确显示批量安装进度
- [ ] --dry-run 模式不受影响
- [ ] `bash scripts/build.sh` 成功

**QA Scenarios**:
```
Scenario: apt 软件批量安装（Bash dry-run）
Tool: Bash
Steps:
  1. bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
  2. 检查输出中包含 "批量" 字样
Expected Result: 同包管理器的软件合并安装
Evidence: .sisyphus/evidence/task-11-batch-install.txt

Scenario: 批量安装回退
Tool: Bash
Steps:
  1. grep -n 'install_batch\|install_software' src/quickstart.sh
  2. 确认回退逻辑存在
Expected Result: 代码中包含批量失败回退逐个安装的逻辑
Evidence: .sisyphus/evidence/task-11-batch-fallback.txt
```

**Commit**: YES
- Message: `feat: 安装分组/批量执行`
- Files: `src/quickstart.sh`, `src/quickstart.ps1`, `src/lang/*.sh`
- Pre-commit: `bash scripts/build.sh`

---

## Final Verification Wave

- [ ] F1. **计划合规审计** — `oracle`
  读计划全文。对每个 "Must Have"：验证实现存在（读文件、curl 端点、运行命令）。
  对每个 "Must NOT Have"：搜索代码库中禁止的模式 — 发现则用 file:line 拒绝。
  检查 .sisyphus/evidence/ 中证据文件存在。对比交付物与计划。
  输出: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **代码质量审查** — `unspecified-high`
  运行 `bash scripts/build.sh` + ShellCheck + PS1 语法检查。
  审查所有变更文件：`as any`/`@ts-ignore`、空 catch、console.log、注释掉的代码、未使用导入。
  检查 AI slop：过度注释、过度抽象、通用命名。
  输出: `Build [PASS/FAIL] | ShellCheck [PASS/FAIL] | PS1 Syntax [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **真实 QA 测试** — `unspecified-high`
  从干净状态开始。执行每个 QA 场景 — 跟随精确步骤，捕获证据。
  测试跨任务集成。测试边界：空状态、无效输入、快速操作。
  保存到 `.sisyphus/evidence/final-qa/`。
  输出: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **范围保真检查** — `deep`
  对每个任务：读 "What to do"，读实际 diff。验证 1:1 — 规格中的都建了，没有超出规格的。
  检查 "Must NOT do" 合规。检测跨任务污染。标记未说明的变更。
  输出: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| 版本 | Commit Message | 包含 Tasks |
|------|---------------|-----------|
| v0.69.0 | `feat: 发布自动化脚本` | Task 0 |
| v0.70.0 | `refactor: install_software() 错误输出捕获` | Task 1 |
| v0.71.0 | `feat(ps1): 视觉进度条` | Task 2 |
| v0.72.0 | `feat(ps1): 安装耗时统计` | Task 3 |
| v0.73.0 | `feat(ps1): 自定义选择模式 --custom` | Task 4 |
| v0.74.0 | `feat: 网络超时友好提示` | Task 5 |
| v0.75.0 | `feat: 权限不足友好提示` | Task 6 |
| v0.76.0 | `feat: 安装前磁盘空间检测` | Task 7 |
| v0.77.0 | `feat: 断点续装` | Task 8 |
| v0.78.0 | `feat: 自我更新 --self-update` | Task 9 |
| v0.79.0 | `feat: 安装前后钩子脚本` | Task 10 |
| v0.80.0 | `feat: 安装分组/批量执行` | Task 11 |

---

## Success Criteria

### 验证命令
```bash
# Bash 功能验证
bash dist/quickstart.sh --dry-run --profile recommended --lang zh --non-interactive
bash dist/quickstart.sh --dry-run --profile recommended --lang en --non-interactive
bash dist/quickstart.sh --help
bash dist/quickstart.sh --self-update --check

# PS1 功能验证
pwsh -NoProfile -File dist/quickstart.ps1 -DryRun -Profile recommended -Lang zh
pwsh -NoProfile -File dist/quickstart.ps1 -DryRun -Profile recommended -Lang en
pwsh -NoProfile -File dist/quickstart.ps1 -?

# i18n 一致性
for f in src/lang/*.sh; do echo "$f: $(grep -c '^LANG_' "$f")"; done

# 构建
bash scripts/build.sh
```

### 最终检查
- [ ] 所有 "Must Have" 已实现
- [ ] 所有 "Must NOT Have" 未出现
- [ ] PS1 功能与 Bash 对齐
- [ ] 10 个语言文件键值数一致
- [ ] 发布自动化可用
- [ ] 错误处理覆盖网络/权限/磁盘场景

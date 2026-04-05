# Quickstart-PC v1.0 Roadmap

## v1.0 发布门槛清单

### ✅ 已完成

- [x] `--validate` 配置校验器
- [x] `--list-software` / `--show-software` / `--search` 软件浏览命令
- [x] 软件状态分级 (stable / partial / experimental / deprecated)
- [x] GitHub Actions 基础 CI (shellcheck + JSON 校验 + dry-run)
- [x] 配置模块化拆分 (config/software/*.json)
- [x] 失败重试策略 (`--retry-failed` / `--fail-fast`)
- [x] 报告导出 (`--report-json` / `--report-txt`)
- [x] 100+ 核心软件可用且状态明确
- [x] 12 个 Profile 体验稳定
- [x] Summary / log 可排障
- [x] 动态终端标题
- [x] 自定义软件选择模式 (`--custom`)
- [x] npm 包管理器自动检测安装

### 🟡 待完成 (v1.0 前必须完成)

- [ ] **PowerShell 功能对齐**: ps1 端实现 `--validate`, `--list-software`, `--show-software`, `--search`, `--report-json/txt`, 状态分级显示
- [ ] **安装命令全面验证**: 所有 stable 级别软件在三平台实际测试通过
- [ ] **错误处理完善**: 网络超时、权限不足、磁盘空间不足等场景的友好提示
- [ ] **国际化完善**: 所有提示信息完整的中英文翻译（目前部分为中文硬编码）
- [ ] **文档完善**: README 与实际行为完全一致，添加完整的故障排除指南
- [ ] **配置 Schema 文档**: 在 README 或单独文档中说明 profiles.json 和 software/*.json 的结构规范

### 🔴 可选 (v1.x 后续版本)

- [ ] 自动更新机制 (`--self-update`)
- [ ] 插件系统 (自定义安装脚本)
- [ ] Web UI 配置编辑器
- [ ] 安装进度持久化 (断点续装)
- [ ] 多语言支持扩展 (日语、韩语等)

## 版本号规划

| 版本 | 内容 |
|------|------|
| v0.55.0 | PowerShell 功能对齐 |
| v0.56.0 | 安装命令全面验证 + 错误处理完善 |
| v0.57.0 | 国际化完善 + 文档完善 |
| v0.58.0 | 配置 Schema 文档 |
| **v1.0.0** | **正式发布** |

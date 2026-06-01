# Proposal: optimize-ios-upload-mode-add-pgyer-auto-upload

## Why

当前 iOS 发布流程把 `ad-hoc`、`TestFlight`、`App Store` 三种目标混在一个 `workflow_dispatch` 表单中，用户需要理解大量“仅某模式生效”的参数，触发体验复杂且误配成本高。与此同时，团队希望在 `ad-hoc` 分发链路中引入蒲公英自动上传，并将上传失败视为阻断条件，以保证分发结果可预期。

## What Changes

- 将现有单一 iOS 发布入口拆分为三个独立工作流入口：`ad-hoc`、`testflight`、`appstore`，每个入口仅暴露该模式需要的参数。
- 引入可复用的 iOS 构建核心流程（reusable workflow 或等价结构），复用签名、构建、导出、产物解析等公共步骤，避免三份流程漂移。
- 为 `ad-hoc` 入口新增蒲公英自动上传能力，并规定上传失败时必须使工作流失败（fail-fast）。
- 明确蒲公英上传成功日志不要求输出安装短链，仅保留可追溯结果字段与错误上下文。
- 明确 `appstore` 入口语义为“仅上传到 App Store Connect（ASC）”，不自动提审、不自动发布。
- `testflight` 入口不强制要求填写内部测试组；未填写时允许仅上传至 TestFlight。
- 旧单入口工作流不再保留过渡期，直接退场。

## Capabilities

### New Capabilities

- `ios-adhoc-pgyer-distribution`: 定义 ad-hoc 产物上传蒲公英的触发条件、鉴权参数、成功输出与失败阻断规则。
- `ios-release-workflow-split`: 定义 iOS 发布入口按分发目标拆分后的参数可见性、模式职责与路由约束。
- `ios-appstore-asc-upload-only`: 定义 appstore 入口仅上传 ASC 的行为边界（不自动提审/发布）。

### Modified Capabilities

- `ios-testflight-release-modes`: 将“单入口 release_mode 选择”调整为“独立 testflight 入口语义”，并保留内部测试组分发相关约束。

## Impact

- 主要影响 CI 工作流：`.github/workflows/` 下 iOS 发布相关 YAML 将拆分与重构。
- 影响密钥管理：新增或细化蒲公英相关 Secrets，按入口最小化暴露。
- 影响运维文档：需要更新触发方式、模式说明、参数说明、Repository Secrets 配置引导与排障指南。
- 影响发布说明文档：需要优化 [docs/github-ios-ipa.md](docs/github-ios-ipa.md) 并新增蒲公英凭据配置说明。
- 影响发布操作习惯：从“单入口多模式”迁移为“按目标选择入口”。

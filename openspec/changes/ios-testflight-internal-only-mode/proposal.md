# Proposal: ios-testflight-internal-only-mode

## Why

当前 iOS 打包工作流将“导出方式”和“分发意图”耦合在一起：`app-store` 常被理解为需要后续上架分发，无法直接表达“仅用于 TestFlight 内部测试”。这导致内部联调场景下操作心智负担高、容易误选参数并触发不必要流程。

## What Changes

- 在工作流输入层新增面向发布意图的模式开关，明确支持 `testflight_internal_only`。
- 保持 iOS 构建签名规则不变：内部 TestFlight 仍使用 `app-store` 导出与上传链路。
- 为内部测试模式增加参数约束与失败提示，避免与外部测试/仅导出 IPA 语义混用。
- 为上传后分配内部测试组能力定义标准行为与回退策略（未配置时给出清晰提示）。
- 更新 iOS GitHub Actions 文档，新增“内部测试快速路径”与模式对照说明。

## Capabilities

### New Capabilities

- `ios-testflight-release-modes`: 定义 iOS 工作流的发布意图模式（仅 IPA、仅内部 TestFlight、TestFlight/上架准备）及其约束与行为。

### Modified Capabilities

- （无）

## Impact

- 受影响工作流：.github/workflows/build-ios-ipa.yml
- 可能新增/使用的 Secret 或输入：内部测试组标识（如组名或组 ID）
- 受影响文档：docs/github-ios-ipa.md、docs/ios-github-actions-checklist.md
- 外部系统影响：App Store Connect TestFlight 构建上传与内部组分配流程

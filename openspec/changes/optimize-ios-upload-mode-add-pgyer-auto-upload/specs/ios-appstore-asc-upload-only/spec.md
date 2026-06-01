# Spec Delta: ios-appstore-asc-upload-only

## ADDED Requirements

### Requirement: appstore 入口必须仅上传到 ASC

The appstore workflow MUST upload build artifacts to App Store Connect only.
`appstore` 入口的自动化行为必须限定为上传构建到 App Store Connect，不得在同一流程中自动提交审核或自动发布。

#### Scenario: appstore 入口执行后仅完成上传

- **WHEN** 用户触发 `appstore` 工作流且上传成功
- **THEN** 构建状态为“已上传到 ASC”，且未触发提审/发布动作

### Requirement: appstore 入口必须使用 app-store 导出语义

The appstore workflow SHALL enforce app-store export semantics.
`appstore` 入口必须强制使用 `app-store` 导出语义与对应签名材料，不得接受 `ad-hoc` 或 `development` 导出组合。

#### Scenario: 导出参数与 app-store 语义不一致时失败

- **WHEN** 上传链路检测到非 `app-store` 导出语义
- **THEN** 工作流在校验阶段失败并提示修正方式

### Requirement: ASC 上传失败必须显式失败

ASC upload failure MUST fail the appstore workflow.
当 ASC 上传过程失败时，工作流必须返回失败状态，并输出错误上下文以支持人工重试。

#### Scenario: ASC API 调用失败

- **WHEN** 上传命令返回错误或鉴权校验不通过
- **THEN** 工作流结束为失败状态并记录失败原因

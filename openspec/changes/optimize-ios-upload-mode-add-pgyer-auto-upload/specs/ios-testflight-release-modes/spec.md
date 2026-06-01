# Spec Delta: ios-testflight-release-modes

## MODIFIED Requirements

### Requirement: 工作流必须提供发布意图模式输入

The workflow MUST expose a dedicated TestFlight release entry as the primary behavior selector for iOS internal delivery.
对于 TestFlight 路径，系统必须提供独立 `testflight` 入口作为主要行为选择器；不得再依赖单入口中的 `release_mode` 进行模式分流。

#### Scenario: 触发 TestFlight 发布时选择独立入口

- **WHEN** 用户在 GitHub Actions 手动触发 TestFlight 分发
- **THEN** 用户通过 `testflight` 独立入口进入流程，且无需填写与 ad-hoc/appstore 相关参数

### Requirement: 内部测试模式必须约束为 app-store 导出并执行上传

Internal TestFlight workflow SHALL enforce app-store export semantics and execute the upload path.
当用户触发 `testflight` 入口时，系统必须使用 `app-store` 导出语义并执行 TestFlight 上传流程，不得允许与 `development` 或 `ad-hoc` 导出语义混用。

#### Scenario: 导出语义不一致时失败

- **WHEN** `testflight` 入口检测到与 `app-store` 不一致的导出或签名参数
- **THEN** 工作流在校验阶段失败，并输出可操作的中文错误提示说明如何修正

#### Scenario: 导出语义一致时进入上传

- **WHEN** `testflight` 入口的导出与签名参数满足 `app-store` 约束
- **THEN** 工作流成功执行 IPA 构建并进入 TestFlight 上传步骤

### Requirement: 内部测试模式应支持自动分配内部测试组

Internal TestFlight workflow MUST support assigning the uploaded build to configured internal tester groups.
当触发 `testflight` 入口并提供内部测试组配置时，系统必须支持将上传后的构建分配到指定内部测试组，并在日志中输出分配目标与结果。

#### Scenario: 已配置内部测试组并分配成功

- **WHEN** 工作流检测到有效的内部测试组配置
- **THEN** 上传后自动执行分配，并输出“上传成功 + 内部分配成功”的结果

#### Scenario: 未配置内部测试组时给出显式结果

- **WHEN** `testflight` 入口缺少内部测试组配置
- **THEN** 工作流仍应完成 TestFlight 上传，并输出“未分配测试组”的显式提示与后续手工分配指引

### Requirement: 工作流文档必须明确模式差异与推荐路径

The documentation MUST clearly describe workflow entry differences and the recommended internal testing path.
文档必须说明 `ad-hoc`、`testflight`、`appstore` 三入口的适用场景、前置 Secret 要求、常见误配与排障建议，并明确内部测试推荐入口为 `testflight`。

#### Scenario: 新用户按文档可完成内部测试首发

- **WHEN** 新用户按文档配置并触发 `testflight` 入口
- **THEN** 用户可在无需外部分发或提审的前提下，将构建用于 TestFlight 内部测试

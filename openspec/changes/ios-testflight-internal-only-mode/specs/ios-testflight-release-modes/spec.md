# Spec Delta: ios-testflight-release-modes

## ADDED Requirements

### Requirement: 工作流必须提供发布意图模式输入
The workflow MUST expose a release intent mode and treat it as the primary behavior selector for iOS delivery.
工作流必须提供可枚举的发布意图模式输入，用于表达“仅导出 IPA”“仅内部 TestFlight”“TestFlight/上架准备”等目标导向场景；模式语义必须稳定且可文档化。

#### Scenario: 触发工作流时可选择发布意图模式
- **WHEN** 用户在 GitHub Actions 手动触发 iOS 打包工作流
- **THEN** 系统提供明确的发布意图模式选项，并可基于该选项驱动后续校验与执行路径

### Requirement: 内部测试模式必须约束为 app-store 导出并执行上传
Internal-only TestFlight mode SHALL enforce app-store export semantics and execute the upload path.
当模式为 `testflight_internal_only` 时，系统必须自动或强校验为 `app-store` 导出语义，并执行 TestFlight 上传流程；不得允许与 `development` 或 `ad-hoc` 导出语义混用。

#### Scenario: 内部测试模式参数不一致时失败
- **WHEN** 用户选择 `testflight_internal_only`，但提供了与 `app-store` 不一致的导出参数
- **THEN** 工作流在校验阶段失败，并输出可操作的中文错误提示说明如何修正

#### Scenario: 内部测试模式参数一致时进入上传
- **WHEN** 用户选择 `testflight_internal_only` 且导出与签名参数满足 `app-store` 约束
- **THEN** 工作流成功执行 IPA 构建并进入 TestFlight 上传步骤

### Requirement: 内部测试模式应支持自动分配内部测试组
Internal-only TestFlight mode MUST support assigning the uploaded build to configured internal tester groups.
当模式为 `testflight_internal_only` 时，系统必须支持将上传后的构建分配到已配置的内部测试组，并在日志中输出分配目标与结果。

#### Scenario: 已配置内部测试组并分配成功
- **WHEN** 工作流检测到有效的内部测试组配置
- **THEN** 上传后自动执行分配，并输出“上传成功 + 内部分配成功”的结果

#### Scenario: 未配置内部测试组时给出显式结果
- **WHEN** 工作流处于 `testflight_internal_only` 模式但缺少内部测试组配置
- **THEN** 工作流按规范输出显式失败或显式降级告警，并给出最小手工补救步骤

### Requirement: 工作流文档必须明确模式差异与推荐路径
The documentation MUST clearly describe release mode differences and the recommended internal testing path.
文档必须说明各模式的适用场景、前置 Secret 要求、常见误配与排障建议，并明确“仅内部测试”推荐路径。

#### Scenario: 新用户按文档可完成内部测试首发
- **WHEN** 新用户按文档配置并选择 `testflight_internal_only`
- **THEN** 用户可在无需外部分发或提审的前提下，将构建用于 TestFlight 内部测试

## ADDED Requirements

### Requirement: iOS 构建产物 MUST 包含微信运行时必需参数

The iOS release build MUST include `WECHAT_APP_ID` and `WECHAT_UNIVERSAL_LINK` in Dart compile-time defines so that runtime WeChat auth client initialization can read valid values.

iOS 发布构建必须将 `WECHAT_APP_ID` 与 `WECHAT_UNIVERSAL_LINK` 注入 Dart 编译期参数，确保运行时微信授权客户端读取到有效值；仅设置环境变量而未进入编译参数不得视为满足要求。

#### Scenario: 发布构建参数缺失

- **当** iOS 发布构建缺少 `WECHAT_APP_ID` 或 `WECHAT_UNIVERSAL_LINK` 编译注入
- **则** 构建流程必须给出明确失败或阻断级告警，且不得默默产出用于发布的包

#### Scenario: 参数注入成功

- **当** iOS 构建流程完整注入微信参数并完成打包
- **则** 应用运行时初始化微信授权客户端时可读取到非空有效配置

### Requirement: 登录入口 SHALL 在 iOS 微信不可用时提供明确反馈

The login UI SHALL display a clear error message when iOS WeChat authorization cannot proceed due to SDK registration failure, launch failure, callback configuration mismatch, or platform exceptions.

当 iOS 微信授权因 SDK 注册失败、无法拉起、回调配置不一致或平台异常而无法继续时，登录入口必须向用户展示明确错误提示，不得出现点击后无反馈。

#### Scenario: SDK 注册失败

- **当** `registerApi` 返回失败或抛出可识别异常
- **则** 登录页必须提示与 `WECHAT_APP_ID`/`WECHAT_UNIVERSAL_LINK` 或 Universal Link 配置相关的可理解信息

#### Scenario: 未捕获平台异常

- **当** 微信登录流程出现未被业务异常包装的运行时异常
- **则** UI 层必须通过兜底异常处理展示错误提示，并恢复按钮可点击状态

### Requirement: iOS 发布流程 MUST 校验微信 Universal Link 依赖一致性

The iOS release process MUST validate that Associated Domains capability, `apple-app-site-association`, and WeChat Open Platform Universal Link settings are aligned before release.

iOS 发布前必须校验 Apple Associated Domains 能力、域名 `apple-app-site-association` 与微信开放平台 Universal Link 配置一致；任一不一致时不得通过发布检查。

#### Scenario: Associated Domains 未配置

- **当** iOS 工程未配置对应 `applinks:` 能力或与微信登记域名不一致
- **则** 发布检查必须失败并输出可执行修复指引

#### Scenario: 发布检查通过

- **当** 上述三处配置一致且微信登录冒烟通过
- **则** 该构建可进入 TestFlight 或正式发布流程
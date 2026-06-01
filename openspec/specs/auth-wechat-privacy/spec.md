## ADDED Requirements

### Requirement: 全平台微信真实登录

The system SHALL provide real WeChat-based sign-in on Android, iOS, and Web using each platform’s official mechanisms (mobile SDKs; Web site / OAuth as required by WeChat). 具体而言：系统必须在 Android、iOS、Web 上提供基于微信的真实登录能力，且使用各平台官方要求的方式（移动端 SDK；Web 端网站应用 / OAuth 等网页授权流程）。

#### Scenario: 用户在移动端完成登录

- **WHEN** 用户在 Android 或 iOS 上发起微信登录且流程成功
- **THEN** 应用必须建立可用于后续 API 与 SSE 的已认证会话

#### Scenario: 用户在 Web 完成登录

- **WHEN** 用户在 Web 上发起微信登录且网页授权流程成功
- **THEN** 应用必须建立与移动端目的等价的已认证会话

### Requirement: 登录页隐私提示文案

The system SHALL display the privacy notice copy below the primary login control. 系统必须在登录页主登录操作下方展示文案 **「请阅读并同意隐私政策」**。

#### Scenario: 用户打开登录页

- **WHEN** 用户进入登录界面
- **THEN** 上述提示必须出现在微信登录按钮（或主登录按钮）下方

### Requirement: 隐私政策应用内打开

The system SHALL open the configured privacy policy URL in-app on mobile (WebView) and inside the app surface on Web (embedded web or equivalent) by default. 系统必须允许用户从登录页通过点击该提示或关联控件打开隐私政策，并在 Android、iOS 上于应用内 WebView 加载配置的隐私政策 URL；在 Web 上必须在应用界面内展示该 URL 内容（嵌入网页或等效方式），默认不得依赖跳转到系统浏览器作为唯一路径。

#### Scenario: 从登录页打开隐私政策

- **WHEN** 用户在登录页激活隐私政策入口
- **THEN** 系统必须按平台约定在应用内展示该 URL 的内容

### Requirement: 认证模块可替换 Mock

The system SHALL allow swapping the auth repository from mock to production without rewriting navigation or session consumers. 除纯 UI 占位外，微信相关集成必须能在**不整体重写认证模块**的前提下替换为生产实现；用于离线演示的 Mock 实现仅允许出现在仓库接口实现之后。

#### Scenario: 从 Mock 切换到生产仓库

- **WHEN** 工程人员将认证仓库由 Mock 换为生产实现
- **THEN** 依赖导航与会话状态的代码必须保持不变

> 客户端 `fluwx`、网页 OAuth 与 `lib/wechat/*` 的实现细节见 OpenSpec 变更 `openspec/changes/app-wechat-sdk-login`。

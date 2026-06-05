## ADDED Requirements

### Requirement: 登录页 MUST 按微信安装状态条件展示微信入口
The login surface SHALL check `fluwx.isWeChatInstalled` before rendering the WeChat sign-in entry; when WeChat is not installed, the entry MUST be hidden.

登录页在展示「微信登录」入口前必须检测 `fluwx.isWeChatInstalled`（或与现有 `FluwxMobileWeChatAuthClient` 一致的等价 API）；当设备未安装微信时，必须**隐藏**微信登录按钮/入口，**不得**展示用户无法使用的微信登录控件。

#### Scenario: iOS 未安装微信时隐藏微信按钮
- **WHEN** 用户在 iOS 设备访问 `/login` 且 `isWeChatInstalled` 为 `false`
- **THEN** 页面不得展示「微信登录」按钮
- **AND** 页面不得弹出「未安装微信」类错误 Toast 或对话框

#### Scenario: iOS 已安装微信时展示微信按钮
- **WHEN** 用户在 iOS 设备访问 `/login` 且 `isWeChatInstalled` 为 `true`
- **THEN** 页面必须展示「微信登录」按钮
- **AND** 点击后必须继续通过 `fluwx` SDK 拉起微信客户端授权

#### Scenario: 检测完成前避免按钮闪烁
- **WHEN** 登录页正在异步检测 `isWeChatInstalled` 且结果尚未返回
- **THEN** 页面不得先展示微信按钮再在检测完成后隐藏
- **AND** 默认应在确认已安装后再展示微信入口（或等价无闪烁策略）

### Requirement: 未安装微信时 MUST NOT 实现网页 OAuth 回退
When WeChat is not installed, the client SHALL NOT launch in-app browser or Safari web OAuth as a fallback for WeChat sign-in.

当设备未安装微信时，客户端**不得**通过应用内浏览器（`ASWebAuthenticationSession`、`SFSafariViewController`、`LaunchMode.inAppBrowserView` 等）或 Safari 发起微信网页 OAuth 作为登录回退；**不得**为 iOS 原生新增 `WECHAT_OAUTH_REDIRECT_URI` 回退配置或 `flutter_web_auth_2` 依赖 solely 服务该场景。

#### Scenario: 未安装微信且无网页 OAuth 路径
- **WHEN** 用户在未安装微信的设备上打开登录页
- **THEN** 应用不得打开微信 OAuth 授权网页
- **AND** 用户须通过 Sign in with Apple（iOS）或账号密码完成登录

#### Scenario: 已安装微信时不强制网页 OAuth
- **WHEN** 用户在已安装微信的设备上点击「微信登录」
- **THEN** 应用必须通过 `fluwx` SDK 授权
- **AND** 不得强制走网页 OAuth 路径

### Requirement: 未安装微信时 MUST 提供替代登录路径
When the WeChat entry is hidden, the login surface MUST still offer Sign in with Apple (iOS) and username-password sign-in.

当微信登录入口因未安装微信而隐藏时，登录页仍必须提供 Sign in with Apple（iOS）与账号密码登录，使用户无需安装微信即可进入应用，符合 App Store 指南 4.2.3(i) 合规策略。

#### Scenario: 未安装微信用户通过 Apple 或账号密码登录
- **WHEN** 审核人员或用户在未安装微信的 iOS 设备上访问登录页
- **THEN** 页面必须可见 Sign in with Apple 按钮与账号密码表单
- **AND** 用户必须能够完成登录并进入应用主流程

#### Scenario: 未安装微信用户不得被引导仅安装微信
- **WHEN** 用户在未安装微信的设备上使用登录页
- **THEN** 应用不得展示无法使用的微信登录入口
- **AND** 不得弹出仅引导用户去 App Store 安装微信而无法继续登录的阻断流程

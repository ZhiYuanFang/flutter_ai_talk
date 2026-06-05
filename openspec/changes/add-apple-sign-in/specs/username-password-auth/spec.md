## MODIFIED Requirements

### Requirement: 登录页必须提供微信与账号密码双入口
The login surface MUST provide username-password sign-in; WeChat sign-in MUST be shown only when WeChat is installed; on iOS Sign in with Apple MUST be provided when WeChat sign-in is offered.
登录页必须提供账号密码登录入口并保留隐私协议入口；微信登录入口须在检测到已安装微信时展示，未安装微信时必须隐藏（见 `ios-wechat-login-visibility`）。在 iOS 上当展示微信登录时，必须同时提供 Sign in with Apple 入口。不得再限制为单一微信登录方式。

#### Scenario: 未登录用户进入登录页（已安装微信）
- **WHEN** 用户访问 `/login` 且 `isWeChatInstalled` 为 `true`
- **THEN** 页面必须可见微信登录按钮与账号密码表单入口
- **AND** 页面必须展示用户协议与隐私政策入口
- **AND** 在 iOS 上必须同时可见 Sign in with Apple 按钮

#### Scenario: 未登录用户进入登录页（未安装微信，iOS）
- **WHEN** 用户在 iOS 设备访问 `/login` 且 `isWeChatInstalled` 为 `false`
- **THEN** 页面不得展示微信登录按钮
- **AND** 页面必须可见 Sign in with Apple 按钮与账号密码表单入口
- **AND** 页面必须展示用户协议与隐私政策入口

#### Scenario: 登录页发起账号密码登录
- **WHEN** 用户输入账号与密码并点击账号登录
- **THEN** 客户端必须调用 `POST /device/app/api/username_login` 完成交互式建会话
- **AND** 成功后必须沿用现有会话成功链路（持久化 token、刷新 `deviceNo`、进入主页）

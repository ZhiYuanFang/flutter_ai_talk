## ADDED Requirements

### Requirement: 登录页必须提供微信与账号密码双入口
The login surface MUST provide both WeChat and username-password sign-in entries.
登录页必须同时提供微信登录入口与账号密码登录入口，并保留隐私协议入口；不得再限制为单一微信登录方式。

#### Scenario: 未登录用户进入登录页
- **WHEN** 用户访问 `/login`
- **THEN** 页面必须可见微信登录按钮与账号密码表单入口
- **AND** 页面必须展示用户协议与隐私政策入口

#### Scenario: 登录页发起账号密码登录
- **WHEN** 用户输入账号与密码并点击账号登录
- **THEN** 客户端必须调用 `POST /device/app/api/username_login` 完成交互式建会话
- **AND** 成功后必须沿用现有会话成功链路（持久化 token、刷新 `deviceNo`、进入主页）

### Requirement: 账号字段必须在提交前规范化并校验
The client SHALL normalize and validate account/password before username login submission.
客户端在发起账号登录或注册前，必须对 `account` 执行 `trim + lowercase`，并校验仅允许 `a-z0-9_` 且长度为 `4-32`；`password` 长度必须为 `6-64`。

#### Scenario: account 含空格与大写
- **WHEN** 用户输入 `"  Test_User  "` 并提交
- **THEN** 客户端必须按 `test_user` 发送到服务端
- **AND** 本地校验通过时才允许发起请求

#### Scenario: account 不符合规则
- **WHEN** 用户输入 `ab` 或 `abc-1`
- **THEN** 客户端不得发起登录请求
- **AND** 必须展示账号规则错误提示（4-32 位，仅 `a-z0-9_`）

#### Scenario: password 长度不符合规则
- **WHEN** 用户输入少于 6 位或超过 64 位密码并提交
- **THEN** 客户端不得发起登录请求
- **AND** 必须展示密码长度错误提示

### Requirement: 用户名登录必须建立与微信一致的会话语义
The system MUST persist session data from username login in the same way as WeChat login.
当 `POST /device/app/api/username_login` 返回成功时，客户端必须解析并持久化 `accessToken` 与 `refreshToken`，并按返回值更新 `deviceNo` 与登录状态，语义与微信登录一致。

#### Scenario: username_login 返回完整会话数据
- **WHEN** 接口返回 `accessToken`、`refreshToken`、可选 `deviceNo`
- **THEN** 客户端必须持久化 token 并更新会话为已登录
- **AND** 若 `deviceNo` 为空，客户端必须清理本地 `deviceNo` 缓存以维持状态一致

#### Scenario: username_login 响应缺少 token
- **WHEN** 接口业务成功但缺少 `accessToken` 或 `refreshToken`
- **THEN** 客户端必须视为失败并提示错误
- **AND** 不得错误进入已登录状态

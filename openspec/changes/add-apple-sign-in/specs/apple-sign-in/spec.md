## ADDED Requirements

### Requirement: iOS 登录页在提供微信登录时必须同时提供 Sign in with Apple
The iOS login surface SHALL offer Sign in with Apple whenever WeChat sign-in is offered on the same screen.
在 iOS 上，当登录页展示微信登录入口时，必须同时展示「通过 Apple 登录」入口，并与账号密码入口并存；Android 与 Web 不得强制展示 Apple 按钮。

#### Scenario: iOS 未登录用户进入登录页
- **WHEN** 用户在 iOS 设备访问 `/login` 且页面展示「微信登录」
- **THEN** 页面必须同时可见 Sign in with Apple 按钮
- **AND** 账号密码表单与隐私协议入口仍必须可见

#### Scenario: Android 登录页
- **WHEN** 用户在 Android 设备访问 `/login`
- **THEN** 页面必须仍可展示微信登录与账号密码入口
- **AND** 不得要求展示 Sign in with Apple 按钮

### Requirement: 客户端必须通过 apple_login 网关建立 Apple 会话
The client SHALL obtain an Apple identity token and call `POST /device/app/api/apple_login` to establish a session.
客户端必须通过 `sign_in_with_apple`（或等价 iOS 授权流程）取得 `identityToken`，并以 lowerCamelCase 请求体调用 `POST /device/app/api/apple_login`（含 `identityToken` 与 `platform: ios`）；服务端与客户端身份仅以 JWT 内 Apple `sub` 为准，**不得**上传或本地持久化 Apple 邮箱。

#### Scenario: Apple 授权成功并完成网关登录
- **WHEN** 用户在 iOS 点击 Apple 登录并同意系统授权，且网关 `apple_login` 返回成功
- **THEN** 客户端必须解析响应中的 `accessToken` 与 `refreshToken` 并持久化
- **AND** 必须按返回值更新 `deviceNo`（若有）与登录状态，语义与微信登录一致
- **AND** 必须将 `SignInChannel` 设为 `apple`

#### Scenario: 网关返回缺少 token
- **WHEN** `apple_login` 业务成功但 `data` 缺少 `accessToken` 或 `refreshToken`
- **THEN** 客户端必须视为失败并提示错误
- **AND** 不得进入已登录状态

#### Scenario: 用户取消 Apple 授权
- **WHEN** 用户在系统 Apple 登录 sheet 上取消授权
- **THEN** 客户端必须向用户展示可理解提示（如 Toast「已取消 Apple 登录」）
- **AND** 不得写入错误 token 或覆盖有效会话

### Requirement: 用户 MAY 仅使用单一登录方式
The client SHALL allow users to use only Apple or only WeChat without binding a second provider.
用户可以不绑定第二登录方式，仅通过 Apple 或仅通过微信使用应用；本能力不强制账号绑定（绑定行为见 `apple-wechat-account-bind`）。

#### Scenario: Apple 登录后不绑定微信
- **WHEN** 用户通过 Apple 登录成功且未执行绑定微信
- **THEN** 客户端必须允许正常使用应用
- **AND** 不得在登录成功流程中强制跳转绑定

### Requirement: AuthRepository 必须暴露 signInWithApple
The `AuthRepository` interface SHALL include `signInWithApple()` implemented by the remote auth repository.
`AuthRepository` 必须声明 `signInWithApple()`，由 `RemoteAuthRepository` 实现并供登录页调用；实现不得依赖微信 `jsCode` 或账号密码字段。

#### Scenario: 登录页调用仓库方法
- **WHEN** 用户在 iOS 点击 Apple 登录按钮
- **THEN** 登录页必须调用 `auth.signInWithApple()`（经 `authRepositoryProvider`）
- **AND** 成功后将用户导航至与微信/账号登录相同的主页会话态

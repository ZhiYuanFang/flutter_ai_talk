## ADDED Requirements

### Requirement: 客户端 MUST 通过微信开放平台能力获取 wxCode 并完成网关登录

The client SHALL obtain a valid WeChat authorization `code` (used as `wxCode` for the gateway) through platform-appropriate means before calling `POST /device/app/api/login`, except when an explicit development override is configured.

应用在调用网关 `POST /device/app/api/login` 之前，必须通过各平台适用的微信开放平台授权流程取得临时 `code`（作为请求体中的 `wxCode`）；仅在显式配置了开发用覆盖（如 `WX_LOGIN_CODE`）且未启用生产取码路径时，才允许跳过 SDK/OAuth。

#### Scenario: Android 成功取码并登录

- **WHEN** 用户在 Android 设备上点击「微信登录」且已完成微信 SDK 注册与拉起授权，用户同意授权  
- **THEN** 应用获得 `wxCode` 并成功调用网关登录接口，会话令牌与 `deviceNo`（若有）按现有逻辑持久化

#### Scenario: iOS 成功取码并登录

- **WHEN** 用户在 iOS 设备上点击「微信登录」且 Universal Link / URL Scheme 配置正确，用户同意授权  
- **THEN** 应用获得 `wxCode` 并成功完成网关登录与会话持久化

#### Scenario: Web 网页授权成功

- **WHEN** 用户在 Web 上点击「微信登录」且 `redirect_uri` 已在开放平台登记，用户完成网页授权重定向回应用  
- **THEN** 应用从回调参数读取 `code` 作为 `wxCode` 并成功完成网关登录

#### Scenario: 用户取消或授权失败

- **WHEN** 用户在微信授权界面取消，或 SDK 返回业务错误  
- **THEN** 应用 MUST 向用户展示可理解提示（如 Toast），且不得写入错误 token 或覆盖有效会话

### Requirement: 应用 MUST NOT 在客户端仓库中嵌入微信 AppSecret

The application MUST NOT bundle WeChat `AppSecret` or equivalent server-only credentials in source code, `--dart-define` defaults, or committed config files.

任何构建产物与仓库源码中不得包含微信 `AppSecret` 或等价仅服务端持有的密钥；`dart-define` 默认值与已提交配置文件中亦不得出现。

#### Scenario: 代码审查与构建检查

- **WHEN** 审查人员检查本仓库与 CI 构建日志  
- **THEN** 未发现 AppSecret 明文；客户端仅包含 AppId、合法回调路径等非机密配置

### Requirement: 登录入口 SHALL 在取码不可用时给出明确指引

The login UI SHALL surface a clear message when WeChat SDK/OAuth is unavailable (e.g., misconfiguration, Web not HTTPS, plugin not registered).

当微信 SDK 未注册、缺少 AppId、Web 非安全上下文或未配置回调等导致无法取码时，登录入口 MUST 提示用户或开发者检查配置，而非无响应或仅静默失败。

#### Scenario: 缺少必要配置

- **WHEN** 未配置微信 AppId（或等价必选参数）用户点击登录  
- **THEN** 界面或 Toast 给出与配置相关的错误说明，且不发起无效的网关请求

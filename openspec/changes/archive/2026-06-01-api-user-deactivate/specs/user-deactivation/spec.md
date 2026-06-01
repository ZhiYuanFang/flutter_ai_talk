## ADDED Requirements

### Requirement: 注销确认需手动输入文本
为了防止用户误操作导致账号被永久删除，系统在执行注销逻辑前，**MUST** 要求用户在确认对话框中手动输入指定的短语“确定注销”。如果输入内容不匹配，确认按钮应处于禁用状态。

#### Scenario: 用户输入错误或未输入时点击确认
- **WHEN** 用户在注销确认框中输入“退出”或保持为空。
- **THEN** “确认注销”按钮应当保持禁用状态或点击后提示输入不匹配，流程不继续。

#### Scenario: 用户输入正确短语后确认
- **WHEN** 用户在确认框中输入“确定注销”并点击确认。
- **THEN** 系统进入下一步调用服务端注销接口的逻辑。

### Requirement: 调用服务端永久注销接口
系统 **MUST** 调用 `/device/app/api/user/deactivate` 接口发起账号销毁请求。该请求 **MUST** 使用 `POST` 方法，并且 **MUST** 包含当前用户的 Authorization 令牌。

#### Scenario: 成功发起注销请求
- **WHEN** App 发送 POST 请求至 `/device/app/api/user/deactivate`，Header 携带有效的 Bearer Token。
- **THEN** 服务端应解析此 Token 并标记该账号为待销毁状态。

### Requirement: 错误处理与状态保持
若注销接口调用失败（网络错误、HTTP 非 200、或业务返回码非 0），系统 **MUST** 中断注销流程。系统 **SHALL NOT** 清除本地会话状态或退出登录，以确保用户能在修复问题后重试，并意识到账号尚未被注销。

#### Scenario: 注销接口返回失败
- **WHEN** 请求注销接口返回错误（如 500 系统错误）。
- **THEN** 系统弹出 Toast 提示“注销连接失败，请重试”，并在当前页面停留，不对本地 Session 执行任何清理。

### Requirement: 成功后的本地清理与跳转
只有在注销接口返回业务成功（code=0）后，系统 **MUST** 清理本地所有敏感信息（包括 Access Token, Refresh Token, Device No, Sign-in Channel），并 **MUST** 将用户导航回初始首页。

#### Scenario: 注销成功
- **WHEN** 服务端返回成功响应（code=0）。
- **THEN** App 自动执行 `SessionController.signOut()` 及相关清理，并重定向至首页。

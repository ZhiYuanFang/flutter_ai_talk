## ADDED Requirements

### Requirement: 账号密码登录成功必须更新本地凭据历史
The client MUST update local credential history after a successful username-password login before navigating away from the login flow.
当 `POST /device/app/api/username_login` 成功并完成既有会话语义（持久化 token 等）后、进入主页之前，客户端必须调用凭据历史 store 记录本次使用的规范化账号与密码；该行为须与 `login-credential-history` 能力中定义的条数上限与安全存储规则一致。

#### Scenario: 登录成功链路写入凭据
- **WHEN** 用户在登录页提交合法账号密码且 `username_login` 成功
- **THEN** 客户端必须在 `context.go('/home')`（或等价进主页导航）之前完成凭据历史写入
- **AND** 写入失败不得阻止进入已登录态（可记录 debug 日志，但不得崩溃）

#### Scenario: 微信登录不得写入账号密码凭据历史
- **WHEN** 用户仅通过微信登录成功
- **THEN** 客户端不得向账号密码凭据历史 store 写入条目

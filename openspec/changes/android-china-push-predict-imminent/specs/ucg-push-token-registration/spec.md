## MODIFIED Requirements

### Requirement: Android token pipeline SHALL use china_push while preserving registration gates
The client push token pipeline SHALL obtain Android tokens via `china_push` and iOS tokens via native APNs, and SHALL register them through the global app push API under login-only eligibility as defined by `app-global-push-registration`. 客户端 Android **必须** 经 china_push、iOS **必须** 经原生 APNs 取 token，并经全局 App 推送 API、**仅登录门闸** 注册。

#### Scenario: Login sufficient without WeChat bind gate
- **WHEN** 用户已登录但未满足旧「UCG 绑微信」检查
- **THEN** 客户端 MUST NOT 仅因未绑微信而拒绝推送注册

#### Scenario: iOS still apns
- **WHEN** 在 iOS 上成功取得设备 token 并注册
- **THEN** `channel` MUST 为 `apns`

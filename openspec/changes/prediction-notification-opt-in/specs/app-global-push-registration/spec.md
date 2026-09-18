## ADDED Requirements

### Requirement: Global push registration MUST respect app notification preference

The client’s global push registration bootstrap and manual sync paths MUST NOT register a vendor push token when the persisted app message-notification preference is disabled, even if the user is logged in and OS notification permission is granted. When the preference is enabled, existing login-gated register behavior remains in force. 全局 push register **必须** 在应用层通知偏好关闭时跳过注册。

#### Scenario: Bootstrap skips register when preference off

- **WHEN** 用户已登录但消息通知偏好为关闭
- **THEN** `syncAppPushRegistration` / bootstrap MUST NOT 调用成功路径的 `POST /app/api/push/register`
- **AND** MUST NOT 仅因登录态而覆盖用户关闭偏好

#### Scenario: Preference on allows register

- **WHEN** 消息通知偏好开启且用户已登录且通道/token 可用
- **THEN** 客户端 MAY 按既有全局注册流程调用 `POST /app/api/push/register`

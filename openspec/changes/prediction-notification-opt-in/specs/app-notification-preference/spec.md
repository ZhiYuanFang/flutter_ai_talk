## ADDED Requirements

### Requirement: App SHALL persist a message-notification preference that gates push registration

The client SHALL maintain a persisted application-level preference for message notifications (default enabled). When the preference is disabled, the client MUST call push unregister (or equivalent) and MUST NOT automatically register vendor push tokens via the global push bootstrap/register path. When the preference is enabled and the user is logged in, registration MAY proceed subject to OS notification permission and existing channel/token rules. 客户端 **必须** 持久化消息通知偏好（默认开启）；偏好关闭时 **必须** unregister 且 **不得** 自动 register。

#### Scenario: User turns preference off in settings

- **WHEN** 已登录用户在消息通知设置将总开关关闭
- **THEN** 客户端 MUST 将偏好持久化为关闭
- **AND** MUST 发起 `POST /app/api/push/unregister`（或既有 unregister 封装）
- **AND** 随后的登录态 bootstrap / sync register MUST NOT 在偏好仍关闭时成功注册新 token

#### Scenario: User turns preference on with OS permission granted

- **WHEN** 用户将总开关打开且系统通知已授权且已登录
- **THEN** 客户端 MUST 允许走既有全局 push register 路径

### Requirement: Settings SHALL expose a notifications page explaining scope and toggle

When the user is logged in, Settings Center MUST show an entry that navigates to a notifications settings page. That page MUST explain what message notifications include (at least predict-imminent event reminders, and that other server-visible pushes sharing the same token are covered by the same switch) and MUST provide the master preference toggle. When OS permission is denied, the page MUST offer a path to request permission or open system settings as appropriate. 已登录时设置中心 **必须** 提供消息通知入口与说明子页及总开关；系统未授权时 **必须** 提供授权或跳转系统设置的路径。

#### Scenario: Open notifications settings

- **WHEN** 已登录用户从设置中心进入消息通知
- **THEN** 客户端 MUST 展示通知范围说明与总开关
- **AND** MUST NOT 暗示可单独关闭预测而保留其它同源推送（一期总开关）

#### Scenario: Guest has no settings entry

- **WHEN** 用户未登录
- **THEN** 设置中心 MUST NOT 展示需登录才能生效的消息通知管理入口（或等价：进入后无法开启有效推送注册）

### Requirement: Client SHALL detect OS notification authorization status

On supported mobile platforms the client SHALL be able to read whether the app’s notification capability is currently authorized (granted/limited vs denied/permanently denied), and MUST refresh that status when the app returns to foreground (resume). Web MAY treat notifications as unsupported and MUST NOT claim OS authorization. 移动端 **必须** 能探测系统通知授权并在 resume 时刷新。

#### Scenario: Resume after enabling in system settings

- **WHEN** 用户从系统设置打开通知后回到 App
- **THEN** 客户端 MUST 重新探测授权状态
- **AND** 若已授权且偏好开启且已登录，MAY 触发 push register 同步

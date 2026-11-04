## ADDED Requirements

### Requirement: Settings Center SHALL expose an iOS-only lock-screen Live Activity status page

When the user is logged in on iOS, Settings Center MUST show a「锁屏通知」（or equivalent）entry that navigates to a dedicated page. The entry MUST NOT appear on Android or Web. The page MUST present the current Live Activity token-registration status in user-visible form and MUST provide a control to manually retry enabling/registration. Registration failure details MUST be shown below the primary controls. The page MUST NOT introduce a separate persisted Off switch for lock-screen notifications in this change. 已登录 iOS 设置中心 MUST 提供「锁屏通知」入口与子页：展示注册显态、支持手动重试，失败信息 MUST 展示在下方；本变更 MUST NOT 新增独立持久化关闭开关。Android/Web MUST NOT 展示该入口。

#### Scenario: Logged-in iOS user opens lock-screen settings

- **WHEN** 已登录用户在 iOS 从设置中心进入锁屏通知
- **THEN** 客户端 MUST 展示当前注册/开通显态
- **AND** MUST 提供可触发手动重试的操作
- **AND** 若最近开通过程失败，MUST 在下方展示失败信息

#### Scenario: Non-iOS has no entry

- **WHEN** 用户在 Android 或 Web 打开设置中心
- **THEN** 客户端 MUST NOT 展示锁屏通知管理入口

#### Scenario: Guest has no lock-screen entry

- **WHEN** 用户未登录
- **THEN** 设置中心 MUST NOT 展示需登录才能生效的锁屏通知管理入口

### Requirement: Lock-screen status UI SHALL expose diagnosable registration stages

The lock-screen settings page MUST make it possible, without system logs, to distinguish at least: unsupported OS version for Push-to-Start, system Live Activities disallowed, listening not started / waiting for system token, per-`attributesKind` (`imminent` and `timing`) Push-to-Start register success or failure, and the latest human-readable failure summary (MUST NOT display the raw push token). 「已开通」MUST require both `imminent` and `timing` Push-to-Start registrations to have succeeded under the client's recorded success criteria. 锁屏通知页 MUST 在无系统日志时可区分上述阶段；MUST NOT 展示原始 token；「已开通」MUST 要求 imminent 与 timing 的 Push-to-Start 均已成功上报。

#### Scenario: Both attributes registered

- **WHEN** 客户端已成功为 `imminent` 与 `timing` 完成 `tokenKind=push_to_start` 的 `live-activity/register`
- **AND** 系统允许 Live Activities 且系统版本支持 Push-to-Start
- **THEN** 页面 MUST 将锁屏通知展示为已开通（或等价绿态）

#### Scenario: HTTP register failure visible

- **WHEN** 用户触发手动重试且 `live-activity/register` 返回错误
- **THEN** 页面下方 MUST 展示可读失败信息（含业务/网络错误摘要）
- **AND** MUST NOT 展示完整 token 字符串

#### Scenario: System token timeout visible

- **WHEN** 用户触发手动重试且在约定超时内未收到系统 Push-to-Start token
- **THEN** 页面下方 MUST 展示表明未收到系统 token 的失败信息

### Requirement: Manual retry SHALL reuse existing listen-and-register pipeline

Tapping enable/retry on the lock-screen settings page MUST reuse the existing ActivityKit listen → token event → `POST /app/api/push/live-activity/register` pipeline. The client MUST NOT add new automatic register triggers solely for this settings feature (cold-start/version one-shot channels are out of scope). Retry MAY force-restart native listening so a fresh token delivery can be observed. 手动开通/重试 MUST 复用既有 listen→token→register 管线；MUST NOT 仅因本设置页新增自动 register 触发点；重试 MAY 强制重启原生监听。

#### Scenario: Retry after upgrade without re-login

- **WHEN** 已登录用户升级后未重新登录、未改动消息通知偏好，并在锁屏通知页点击重试
- **THEN** 客户端 MUST 尝试重新监听并在收到 token 后走 `live-activity/register`
- **AND** MUST 根据结果更新显态或下方失败信息

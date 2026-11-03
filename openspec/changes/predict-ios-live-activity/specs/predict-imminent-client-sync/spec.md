## MODIFIED Requirements

### Requirement: Predict-imminent offline delivery SHALL reuse global push registration

Offline delivery of predict-imminent reminders SHALL continue to allow pending sync without a separate third-party push SDK. Device alert tokens remain on `POST /app/api/push/register`. On **iOS**, Live Activity / Push-to-Start tokens MUST use `POST /app/api/push/live-activity/register` per `predict-imminent-live-activity` and twin `predict-live-activity-push`; the client MUST present predict-imminent via Live Activity rather than relying on a normal visible APNs alert UI. On **Android**, visible vendor notification consumption MAY remain. The client MUST still allow pending sync when push / Live Activity tokens are not yet available.

预测临近 pending 同步 MUST NOT 另接第三方推送 SDK；设备 alert token 仍走 `POST /app/api/push/register`。**iOS** Live Activity token MUST 走 `POST /app/api/push/live-activity/register`（见 `predict-imminent-live-activity` 与对端 change）；展示 MUST 按 Live Activity，不得依赖普通可见 alert UI。**Android** MAY 继续可见厂商通知。尚无 token 时仍 MUST 允许 pending 同步。

#### Scenario: No token still allows pending sync

- **WHEN** 设备尚未成功 register 推送或 Push to Start token
- **THEN** 客户端仍 MUST 允许 pending 同步

#### Scenario: iOS client expects Live Activity presentation

- **WHEN** 已登录用户在支持的 iOS 设备上使用预测临近提醒能力
- **THEN** 客户端 MUST 按 Live Activity 路径准备展示（token + Extension），MUST NOT 以本仓实现改回依赖普通预测 alert UI

#### Scenario: Android may keep visible notification

- **WHEN** 在 Android 设备上接收预测临近提醒
- **THEN** MAY 继续使用既有可见厂商通知；本需求 MUST NOT 要求 Android 锁屏 Live Activity

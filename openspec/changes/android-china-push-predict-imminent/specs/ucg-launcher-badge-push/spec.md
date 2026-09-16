## ADDED Requirements

### Requirement: Killed-app visible pushes SHALL still depend on server notification payloads
When the app process is killed, visible system notifications (including UCG badge-related and predict-imminent alerts) SHALL continue to be delivered by vendor channels using server-sent notification payloads; the Android client MUST NOT reintroduce a parallel self-managed OEM push SDK beside `china_push`; tokens MUST come from global `POST /app/api/push/register`. 杀进程可见通知仍依赖服务端可见 payload；Android **不得** 在 china_push 之外再维护并行自研厂商推送 SDK；token **必须** 来自全局注册。

#### Scenario: No parallel Android OEM stack
- **WHEN** 检查 Android 工程推送实现
- **THEN** 自研 HMS/MiPush token 路径 MUST 已移除；厂商通道经 china_push 接入；注册 path MUST 为 `/app/api/push/register`

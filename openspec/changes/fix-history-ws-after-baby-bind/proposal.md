## Why

新账号登录并绑定宝宝 ID 后，历史 WebSocket 仍报「未绑定设备，无法订阅历史推送」，切后台回来也无法恢复；切换已绑定账号后却能连上。根因是 access JWT 在登录时签发、`device_no` 为空，绑定成功后客户端只更新了本地 `deviceNo` 缓存而未刷新 token，网关 WS 鉴权以 JWT 内 `device_no` 为准。与此同时，自动重连期间「正在重连…」横幅干扰用户，且服务端「设备未注册」类错误文案未按产品「宝宝ID」语义展示。

## What Changes

- 绑定宝宝（`bindwx` / `auto_save`）成功后，客户端 **必须** 强制刷新 access token（`token/refresh`），再 reset strike 并重连历史 WebSocket。
- 历史 WS 建连前：若本地已有 `deviceNo` 但 JWT 缺少 `device_no` claim，**必须** 先 refresh 再 auth。
- **修改** 主页 WS 横幅：`autoReconnecting`（含后台 lifecycle 触发的静默重连）期间 **不得** 展示连接状态横幅；仅在判定连接失败（如 `gaveUp`，或 `disconnected` 且当前无进行中的自动重连 attempt）时展示未连接提示。
- **修改** 用户可见错误映射：服务端返回含「设备未注册」「请先注册设备号」等文案时，Toast 展示 **「宝宝ID未绑定」**（或等价宝宝语义）；WS `error` 帧中「未绑定设备，无法订阅历史推送」在 token 已刷新仍失败时可映射为「请先绑定宝宝信息」类文案（实现层按 design 统一入口）。

## Capabilities

### New Capabilities

- `history-ws-token-sync-after-bind`：绑定宝宝后会话 token 与 WS 鉴权所需 `device_no` claim 的同步、建连前校验与重连顺序。

### Modified Capabilities

- `home-history-ws-status-banner`：自动重连进行中不展示横幅；仅在连接失败/需用户介入的未就绪态展示。
- `device-identity-sync`：补充绑定后 token 与 deviceNo 一致性要求（超越本地 prefs 同步）。
- `user-facing-baby-id-terminology`：补充 API/WS 错误文案的宝宝ID术语映射。

## Impact

- **Flutter**：`session_controller.dart`（强制 refresh）、`baby_bind_screen.dart`、`remote_feed_repository.dart`（建连前 token 校验）、`home_screen.dart` / `home_history_ws_status_banner.dart`（横幅可见性）、新增或扩展 API 错误文案映射（如 `gateway_user_message.dart`）。
- **后端**：无契约变更；`token/refresh` 与 WS 鉴权行为沿用现网。
- **基线**：`feed-history-sync`、`history-ws-reconnect` 行为不变（重连成功仍不 list 刷新）。

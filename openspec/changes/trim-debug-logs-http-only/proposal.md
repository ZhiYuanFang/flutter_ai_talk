## Why

Debug 构建下控制台同时输出 `HomeHistoryLog`（~59 处）、WebSocket 连接日志、语音/UCG 等零散 `debugPrint`，淹没了 `ApiHttpLog` 的 HTTP 接口日志，日常联调难以快速定位 API 请求。产品决策：debug 控制台**仅保留**经 `ApiClient` 的 HTTP 请求/响应日志，并为每条增加时间戳。

## What Changes

- `ApiHttpLog` 每条输出前缀增加 ISO8601 时间戳（毫秒）。
- **删除** `HomeHistoryLog` 类及全部 `.d()` 调用点（4 文件，~59 处）。
- **删除** WebSocket 调试输出：`RemoteFeedRepository` / `UcgRepository` 不再向 `ResilientWebSocketClient` 传入 `log` 回调（或等价 no-op）。
- **删除** 其余 debug 专用 `debugPrint`/`print`：`voice_asr_ws_client`、`ucg_video_playback`、`ucg_album_picker_screen`、`ucg_push_registration_service`、`event_catalog_notifier`、`home_screen` bootstrap、`system_stt_home_speech_recognizer`、`force_ipv4_http_overrides` 等。
- 不扩展 HTTP 日志覆盖范围（token refresh 直调 `http.post`、OSS 预签名 PUT 仍不在 v1 范围）。

## Capabilities

### New Capabilities

- `api-http-debug-log`：debug 模式下唯一允许的 console 网络诊断输出规范（`ApiHttpLog` + 时间戳 + 脱敏）。

### Modified Capabilities

（无 — 无用户可见行为或对外 API 契约变更。）

## Impact

- **Flutter**：`api_http_log.dart`、`home_history_store.dart`、`home_history_notifier.dart`、`home_screen.dart`、`remote_feed_repository.dart`、`ucg_repository.dart` 及上列零散模块。
- **Release 构建**：无影响（现有日志均已 `kDebugMode` 守卫或无输出）。
- **调试体验**：WS/历史/cache 问题需依赖断点或其它工具，不再从 logcat 追踪。

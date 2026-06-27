## 1. ApiHttpLog 增强

- [x] 1.1 `api_http_log.dart` 增加 `_ts()`，request/response/retryAfter401 三处输出 ISO8601 时间戳
- [x] 1.2 确认脱敏与 `kDebugMode` 守卫未破坏

## 2. 删除 HomeHistoryLog（方案 A）

- [x] 2.1 删除 `home_history_store.dart` 中 `HomeHistoryLog` 类及全部 `.d()` 调用
- [x] 2.2 删除 `home_history_notifier.dart` 全部 `HomeHistoryLog.d(...)` 及无用 import
- [x] 2.3 删除 `home_screen.dart` 全部 `HomeHistoryLog.d(...)` 及无用 import
- [x] 2.4 删除 `remote_feed_repository.dart` 中 `_logWs`、`_logDataKeys`（若仅服务日志）及全部 `HomeHistoryLog` 引用；`WsConnectionConfig` 不传 `log`

## 3. 删除 WebSocket 与其它 debug 输出

- [x] 3.1 `ucg_repository.dart`：移除 `log: (m) => debugPrint(m)` 及无用 import
- [x] 3.2 `voice_asr_ws_client.dart`：删除全部 debug 用 `debugPrint`
- [x] 3.3 `ucg_video_playback.dart`：删除 `[ucg_video]` debugPrint
- [x] 3.4 `ucg_album_picker_screen.dart`：删除 debugPrint 块
- [x] 3.5 `ucg_push_registration_service.dart`：删除 debugPrint
- [x] 3.6 `event_catalog_notifier.dart`：删除 `[EventCatalog]` debugPrint 及无用 import
- [x] 3.7 `home_screen.dart`：删除 bootstrap/voice 相关 debugPrint（保留 HomeHistory 任务已覆盖部分）
- [x] 3.8 `system_stt_home_speech_recognizer.dart`：删除 debugPrint
- [x] 3.9 `force_ipv4_http_overrides.dart`：删除 kDebugMode 下 `print` 诊断

## 4. 验收

- [x] 4.1 `rg "HomeHistoryLog|\\[HomeHistory\\]" app/lib` 无匹配
- [x] 4.2 `rg "debugPrint|print\\(" app/lib` 无 debug 诊断输出（允许注释/字符串误报需人工确认）
- [x] 4.3 debug 运行触发 HTTP 请求：控制台仅见带时间戳的 `[ApiHttp]` 行
- [x] 4.4 `dart analyze` 通过

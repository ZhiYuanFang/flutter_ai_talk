## Context

- `ApiHttpLog`（`api_http_log.dart`）已在 `ApiClient._send` 统一记录 HTTP，含脱敏，但**无时间戳**。
- `HomeHistoryLog` 散布于主页历史链路（notifier、store、screen、remote_feed_repository），是控制台最大噪音源。
- `ResilientWebSocketClient` 通过 `WsConnectionConfig.log` 回调输出 history / ucg-chat WS 日志。
- 其它模块有独立 `debugPrint`（语音 ASR WS、UCG 相册/视频/推送、事件目录、IPv4 等）。
- 用户选定**方案 A**：删干净，不留空实现或 dead call sites。

## Goals / Non-Goals

**Goals:**

- Debug 模式下控制台**仅**出现 `[ApiHttp]` 前缀的 HTTP 请求/响应/401 重试日志。
- 每条 `[ApiHttp]` 日志含 ISO8601 时间戳（毫秒精度）。
- 删除 `HomeHistoryLog` 及全部调用；删除 WS 与其它 debug 专用输出。

**Non-Goals:**

- 不记录 token refresh 直调 `http.post`、OSS 预签名 PUT。
- 不改变 Release 行为（现有日志已 guarded）。
- 不引入统一 `AppLog` 分类框架（方案 C）。
- 不删除用户可见 SnackBar/Toast 错误提示。

## Decisions

### 1. 时间戳格式：ISO8601 本地时间

**选择**：`DateTime.now().toIso8601String()`，与已删除的 `HomeHistoryLog` 格式一致。

**示例**：`[ApiHttp] 2026-06-25T14:30:01.234 → GET https://...`

**备选**：仅 `HH:mm:ss.SSS` — 更短但跨日调试不便；不采用。

### 2. 删除 HomeHistoryLog（非空实现）

**选择**：删除 `HomeHistoryLog` 类；逐文件移除 `.d(...)` 调用及仅用于日志的辅助（如 `_logDataKeys` 若仅服务日志）。

**理由**：方案 A，避免 dead code。

### 3. WebSocket：不传 log 回调

**选择**：`RemoteFeedRepository` 删除 `_logWs` 及 `log:` 参数；`UcgRepository` 删除 `log: (m) => debugPrint(m)`。`ResilientWebSocketClient._log` 在 `log == null` 时已有 no-op（需确认，否则补 guard）。

### 4. 零散 debugPrint：整行删除

**选择**：删除 debug 诊断用的 `debugPrint`/`print` 语句；保留业务逻辑与 catch 块（空 catch 或仅 UI 反馈）。

**不删**：`showGlassConfirmDialog` 等 UI 组件名误匹配项。

### 5. ApiHttpLog 内部封装时间戳

**选择**：私有 `_ts()` 方法，request/response/retry 三处统一前缀。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| WS/历史分页问题难从 logcat 排查 | 团队约定：需要时用断点或临时加日志 |
| 漏删某处 debugPrint | tasks 含 grep 验收步骤 |
| `_logWs` 删除后 `_prepareWsConnectContext` 内日志调用需一并清理 | tasks 按文件清单 |

## Migration Plan

单 PR；无配置或后端依赖。回滚：恢复删除的 log 调用即可。

## Open Questions

（无。）

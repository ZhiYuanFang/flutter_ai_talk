## Why

iOS 对同一 host（`pangbao.cuplay.top`）的并发连接上限约 6 条（HTTP、WebSocket、WKWebView 共享）。用户登录成功后，客户端会在极短时间内同时发起：历史 WebSocket 建连（且 `feedRepositoryProvider` 在 `isLoggedIn` / `deviceNo` 监听上重复 reconnect）、`ColdStartBackgroundSync` 并行 HTTP（event catalog + history list）、登录页/主页 `loadBaby` 等，导致连接槽位耗尽。表现为登录后所有 `pangbao.cuplay.top` 请求失败（含无鉴权的版本检查与隐私政策 WebView），而独立域名的 notify 接口仍正常；Android 不受影响。

## What Changes

- **登录后网关错峰（stagger）**：已登录用户的 catalog/history 远端 sync MUST 串行或限并发（≤2），完成后再允许历史 WebSocket 建连。
- **历史 WS 建连入口去重**：移除 `feedRepositoryProvider` 在 `isLoggedIn` / `deviceNo` 变化时对 `reconnectHistoryWebSocket` 的抢先调用；登出时 tearDown；token 轮换与 manual reconnect 保留既有行为。
- **Home 订阅顺序**：`HomeScreen` 在 `ColdStartBackgroundSync` 完成后再通过 `watchLatest()` 触发 WS desired（或等价 gate），避免 HTTP burst 与 WS handshake 重叠。
- **（可选）登录页重复 HTTP**：减少 `login_screen._afterLoginSuccess` 与主页 bootstrap 对 `loadBaby` 的重复调用，降低峰值连接数。
- **不改变**：notify 独立基址、鉴权契约、WS 传输层 `ResilientWebSocketClient` 实现、Android 行为（串行化对 Android 无害）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `event-catalog-cache`：扩展「后台 sync 不得重复阻塞」——已登录用户 catalog/history 远端 refresh MUST 错峰，且 MUST 在历史 WebSocket 建连之前完成或释放连接槽位。
- `history-ws-reconnect`：增补登录后会话建连时序——历史 WebSocket MUST 由 `watchLatest()` 订阅触发，MUST NOT 在登录瞬间与 gateway HTTP burst 并行抢占同 host 连接；登出 MUST tearDown。

## Impact

- **Bootstrap**：`app/lib/bootstrap/cold_start_background_sync.dart`
- **Provider**：`app/lib/providers/repositories.dart`（`feedRepositoryProvider` 监听精简）
- **UI**：`app/lib/ui/home_screen.dart`（bootstrap 与 WS 订阅顺序）
- **（可选）**：`app/lib/ui/login_screen.dart`（去掉重复 `loadBaby`）
- **OpenSpec**：`event-catalog-cache`、`history-ws-reconnect` capability delta
- **无**新 HTTP 接口、无 Android R8 / 新 WS 传输实现

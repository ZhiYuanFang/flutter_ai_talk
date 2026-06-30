## Context

- **问题**：iOS 登录后对 `pangbao.cuplay.top` 同 host 并发连接（HTTP + WebSocket + WKWebView）超过系统上限（约 6），导致鉴权 API、无鉴权 `version/check`、隐私政策 WebView 均失败；`notify.cuplay.top` 正常。
- **现状**：
  - `ColdStartBackgroundSync` 已登录路径用 `Future.wait([catalog bootstrap, history refresh])` 并行 HTTP。
  - `feedRepositoryProvider` 在 `isLoggedIn` 与 `deviceNoNotifier` 变化时立即 `reconnectHistoryWebSocket(resetStrike: true)`，早于 `HomeScreen.watchLatest()`。
  - `HomeScreen._init` 同时启动 bootstrap、dialog bootstrap、`watchLatest()` WS 订阅。
  - 注释已说明「建连由 `watchLatest()` 触发」，但 provider 层抢先 reconnect 与之矛盾。
- **约束**：须继续经 `ResilientWebSocketClient`；不得新增手写 WS 传输；Debug 日志走 `AppDebugLog`/`ApiHttpLog`；不新增 `*_test.dart`。

## Goals / Non-Goals

**Goals:**

- 登录后进主页，gateway HTTP burst 与历史 WebSocket 握手**错峰**，同 host 峰值连接 ≤ 4。
- 历史 WS **单一建连入口**：`watchLatest()` 订阅 + `setConnectionDesired(true)`；登出 tearDown。
- 保留 token 轮换 reconnect、deviceNo 绑定页显式 reconnect、手动横幅 reconnect、3-strike/gave-up 语义。
- iOS 登录后设置页「检查更新」、隐私政策 WebView、鉴权 API 恢复正常；Android 行为不回归。

**Non-Goals:**

- 不修改 notify 独立基址、网关 API 契约。
- 不为 WKWebView 安装 `HttpOverrides`；不改为 Safari 外链打开隐私政策。
- 不调整 `FORCE_IPV4` 默认值（可后续独立 change）。
- 不重构全局 HTTP Client 单例（除非 stagger 不足时再评估）。

### 6. Gateway Bootstrap Gate（P2）

**决策**：新增 `GatewayBootstrapGate.ensureLoggedInComplete`：串行 `ColdStartBackgroundSync` + `loadBaby`；登出 `reset()`。`HomeScreen` 在 `isLoggedIn` false→true（KeepAlive 不重跑 `_init`）时 MUST await gate 后再建 WS，且 MUST NOT 在 listen 中并行 `_refreshEventCatalogIfReady`。

### 7. 拆分 watchLatest 订阅与建连（P0）

**决策**：`watchLatest()` 仅 `setSubscribeActive(true)`；`ensureHistoryWebSocketConnected()` 在 gate + `_runPostLoginBootstrap` 完成后调用。iOS 额外 `await Future.delayed(2s)` 再建连。

### 8. iOS WS 重连 backoff（P1）

**决策**：`ResilientWebSocketClient` 在 `sink.close()` 后 brief settle delay（iOS 300ms）；iOS 首包 reconnect 3s、precondition 1.5s（Android 不变）。

## Decisions

### 1. 已登录 ColdStartBackgroundSync 改为串行 HTTP

**决策**：`ColdStartBackgroundSync._run` 在 `loggedIn == true` 时，将

```dart
await Future.wait([catalog bootstrap, history refresh]);
```

改为**串行**：

```dart
await ref.read(eventCatalogProvider.notifier).bootstrap();
await ref.read(homeHistoryProvider.notifier).refreshFromRemote();
```

**理由**：两路 HTTP 并行 + WS + loadBaby 易触顶 iOS 连接槽；串行增加数百 ms 延迟，可接受。Android 无负面影响。

**备选**：iOS-only 串行 — 增加 `Platform.isIOS` 分支，维护成本高；统一串行更简单。

### 2. 移除 feedRepositoryProvider 抢先 reconnect 监听

**决策**：

- **删除** `ref.listen(isLoggedIn → tryReconnectHistoryWs)`。
- **删除** `ref.listen(deviceNoNotifier → tryReconnectHistoryWs)`（deviceNo 变更改由 `watchLatest` 已订阅时的 `shouldConnect` + precondition retry 处理；绑定页保留显式 `reconnectHistoryWebSocket`）。
- **保留** `accessToken` rotation listener、`bindAuthenticatedWsSession`（refresh 结束 reconnect）、登出时 `setConnectionDesired(false)` / tearDown。

**理由**：与 v2.0.3「建连由 `watchLatest()` 触发」一致；消除登录瞬间双重重连。

**登出**：在 `isLoggedIn` false 时调用 `remote.reconnectHistoryWebSocket()` 或 `setConnectionDesired(false)` — 现有 false 分支可改为仅 tearDown（`setConnectionDesired(false)`），不发起新 connect。

### 3. HomeScreen：bootstrap 完成后再订阅 watchLatest

**决策**：调整 `_init` 顺序：

1. 先 `await _bootstrapHomeData()`（内含 `ColdStartBackgroundSync.run`）。
2. 再 `feed.watchLatest().listen(...)`（触发 WS desired）。
3. `_runHomeDialogBootstrap`（notify + post-login version/baby）可与 bootstrap **并行**或在其后 — notify 走独立 host，不占用 pangbao 槽位；`_runPostLoginBootstrap` 的 `loadBaby`/`version/check` 应放在 **catalog/history sync 之后**（可合并进 bootstrap 末尾或保持 postFrame 但在 bootstrap 之后）。

**理由**：保证 WS 握手时 HTTP 峰值已过去。

**备选**：Provider 层 `gatewayBootstrapCompleteProvider` — 过度抽象；HomeScreen 顺序调整足够。

### 4. 减少 login_screen 重复 loadBaby（可选）

**决策**：`LoginScreen._afterLoginSuccess` 移除 `loadBaby` + theme persist，仅 `deviceNo refresh` + `context.go('/home')`；宝宝信息与主题由 home `_runPostLoginBootstrap` / bootstrap 统一拉取。

**理由**：登录页 + 主页各一次 `user/get` 浪费连接；去掉可降低峰值。

**风险**：登录后跳转前无 sex 主题 — home bootstrap 会 `loadBaby` 并 `applyUserThemeBaseline`，Splash 已做过本地主题，可接受。

### 5. deviceNo 绑定页显式 reconnect 保留

**决策**：`baby_bind_screen` 成功绑定后仍调用 `reconnectHistoryWebSocket(resetStrike: true)`。

**理由**：用户显式操作后需立即 WS；此时非登录风暴场景。

## Risks / Trade-offs

- **[Risk] WS 就绪延迟 0.5–2s** → 登录后短暂 `isHistoryWebSocketReady == false`；已有 UI 横幅与 optimistic 路径，可接受。
- **[Risk] deviceNo 变更不再自动 reconnect** → 依赖 `shouldConnect` precondition retry；若 home 未 mount 可能延迟 — 绑定页仍显式 reconnect。
- **[Risk] 串行 sync 略慢** → 有磁盘缓存时 UI 已 hydrate，用户无感。
- **[Risk] 登出 tearDown 行为变化** → 须验证登出后 WS 关闭、未登录不再 connect。

## Migration Plan

- 纯客户端行为调整；无后端、无数据迁移。
- 发版前在 **iOS 真机**验证：登录 → 设置检查更新 / 隐私政策 / 首页历史 WS 就绪。
- Android 冒烟：登录、历史 WS、添加事件。
- 回滚：还原 `repositories.dart` 监听与 `Future.wait` 即可。

## Open Questions

（无 — 探索阶段已确认根因为 iOS 同 host 连接耗尽，层 1+2 方案足够。）

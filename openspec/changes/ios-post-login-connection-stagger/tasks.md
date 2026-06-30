## 1. Gateway HTTP 错峰

- [x] 1.1 修改 `ColdStartBackgroundSync._run`：已登录时将 catalog bootstrap 与 history `refreshFromRemote` 由 `Future.wait` 改为**串行** await；保留 in-flight dedup 与未登录游客路径不变

## 2. 历史 WS 建连入口去重

- [x] 2.1 修改 `feedRepositoryProvider`：移除 `isLoggedIn` 与 `deviceNoNotifier` 监听中对 `tryReconnectHistoryWs` 的调用；登出时改为 `setConnectionDesired(false)` / tearDown（不发起新 connect）
- [x] 2.2 保留 `accessToken` rotation listener 与 `bindAuthenticatedWsSession`；确认 `baby_bind_screen` 显式 `reconnectHistoryWebSocket` 仍可用

## 3. HomeScreen 订阅顺序

- [x] 3.1 调整 `HomeScreen._init`：先 `await _bootstrapHomeData()`（含 `ColdStartBackgroundSync`），再订阅 `feed.watchLatest()` 触发 WS；WS phase/ready 监听可提前注册
- [x] 3.2 确保 `_runPostLoginBootstrap`（version/check、loadBaby）不在 catalog/history sync **之前**与 WS 并行抢占 pangbao 连接（postFrame 且在 bootstrap 之后，或合并顺序）

## 4. 登录页去重（可选）

- [x] 4.1 精简 `LoginScreen._afterLoginSuccess`：移除重复 `loadBaby`/主题 persist，交由 home bootstrap；保留 `deviceNo refresh` 与 `context.go('/home')`

## 5. 验收

- [ ] 5.1 **iOS 真机**：未登录可开隐私政策 → 登录 → 设置「检查更新」成功、隐私政策 WebView 可加载、首页历史 WS 在 bootstrap 后就绪（允许 1–2s 延迟）
- [ ] 5.2 **Android 冒烟**：登录、添加历史事件、WS 推送、登出后 WS 关闭无异常
- [ ] 5.3 确认 notify banner 在未登录/已登录均正常（独立 host 不受影响）

## 6. 账号管理网络异常逃生

- [x] 6.1 `account_management_sheet`：profile 加载失败时展示友好文案、「重试」与「切换账号」（不依赖 profile 接口成功）
- [x] 6.2 `_switchAccount` 切换前调用 `disconnectHistoryWebSocket()`，尽快释放 pangbao 连接槽位

## 7. Gateway Bootstrap Gate（P2）

- [x] 7.1 新增 `GatewayBootstrapGate`：`ensureLoggedInComplete` 串行 `ColdStartBackgroundSync` + `loadBaby`；登出 `reset()`
- [x] 7.2 `HomeScreen`：`isLoggedIn` false→true 时 `await _onLoggedInWhileHomeMounted()`（gate → version → WS），**不**再并行 `_refreshEventCatalogIfReady` / `_reloadHistoryIfLoggedIn`
- [x] 7.3 `_init` 已登录路径改走 gate；游客仍 `_bootstrapHomeData()`

## 8. 历史 WS 延迟建连（P0）

- [x] 8.1 `watchLatest()` 仅 `setSubscribeActive(true)`；新增 `ensureHistoryWebSocketConnected()` 显式建连
- [x] 8.2 gate + postLogin 完成后 iOS `await Future.delayed(2s)` 再 `ensureHistoryWebSocketConnected()`

## 9. iOS WS 重连风暴缓解（P1）

- [x] 9.1 `ResilientWebSocketClient`：close 后 brief settle delay（iOS 300ms）
- [x] 9.2 iOS 首包 reconnect backoff 3s、precondition retry 1.5s（Android 保持 1s / 500ms）

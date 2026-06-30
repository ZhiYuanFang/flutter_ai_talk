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

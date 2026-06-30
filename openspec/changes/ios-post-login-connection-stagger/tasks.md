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

## 10. iOS 槽位探针（临时）

- [x] 10.1 `AppEnv.disablePangbaoWebSocketSpike`（`--dart-define=DISABLE_PANGBAO_WS`）：历史 WS 全入口跳过（**默认 false**；探针时 `--dart-define=DISABLE_PANGBAO_WS=true`）
- [x] 10.2 语音 ASR WS `VoiceAsrWsClient.connect()` 同开关跳过（同 host）
- [x] 10.3 **iOS 真机探针结论**：禁 WS 后登录 HTTP 仍失败 → 根因含 **登录 HTTP burst + logo 6 并发占槽**，不单是历史 WS
- [x] 10.4 探针结论后：`DISABLE_PANGBAO_WS` 默认改回 `false`；`tryReconnectHistoryWs` 须 `GatewayBootstrapGate.isLoggedInComplete`

## 11. 登录 HTTP 错峰（探针后）

- [x] 11.1 `app.dart`：已登录时不 `unawaited(ColdStartBackgroundSync)`，仅游客冷启动补 sync
- [x] 11.2 iOS 已登录：catalog refresh **不**立即 logo 下载；gate + version 后 `runDeferredLogoDownloads()`
- [x] 11.3 iOS logo 并发 6→2；登出 `cancelLogoDownloads()` 释放 in-flight HTTP
- [x] 11.4 KeepAlive 登录路径补 `_runHomeDialogBootstrap`（notify）

## 12. iOS 登录 HTTP 探针页（诊断）

- [x] 12.1 `IOS_LOGIN_HTTP_PROBE` + `/dev/ios-login-http-probe` 路由（须已登录）
- [x] 12.2 登录与冷启动已登录跳转 `AppEnv.postLoginRoute`（不 mount Home）
- [x] 12.3 4 接口（options/list/user/get/version）**并发/串行**测试 + 结果展示
- [ ] 12.4 iOS 真机记录：并发 vs 串行 vs 进 home 对比结论
- [x] 12.5 探针页增加 **history WS** + **ucg/chat WS**（独立 `ResilientWebSocketClient`，不 `watch(ucgRepositoryProvider)`）
- [x] 12.6 模式：**先 WS 再 HTTP 并发**、**WS+HTTP 同时并发**；账号/Apple 用户可「强制 chat WS」
- [x] 12.7 探针 dispose / 「断开 WS」释放连接槽位
- [ ] 12.8 iOS 真机记录：HTTP-only vs HTTP+2WS 并发 vs 串行对比结论

## 13. Home 全量探针（wx 用户定位）

- [x] 13.1 探针项注册表：Home 进房 HTTP/WS（含 Voice ASR、UCG unread×2、logo、notify）+ Home 时序分组
- [x] 13.2 逐项勾选 + **并发已选** / **Home 时序**；`全选 Home(wx)` 预设；槽位预估
- [x] 13.3 仍不 mount `feedRepositoryProvider` / `ucgRepositoryProvider`；logo 可调数量/并发
- [ ] 13.4 iOS 真机（wxId）：二分最小复现集 + CLEAN vs POST-HOME 对比记录
- [x] 13.5 logo **全量 catalog + 全并发/6 并发**；**Home 真实并行**（init 旁路 ∥ gate，logo 不 await）

## 14. pangbao 传输生命周期（POST-HOME 污染 fix）

- [x] 14.1 `releasePangbaoHomeTransports`：history WS + UCG chat WS + Voice ASR disconnect + cancel logo + gate reset
- [x] 14.2 登出 / 切账号 / `HomeScreen.dispose`（离开 Home）统一 release
- [x] 14.3 UCG repo **gate 后** `mountUcgHomeTransportsIfEligible`；移除 initState/build 抢先 mount
- [x] 14.4 Voice ASR 建连移至 gate 后（与 history WS 同 `_startHomePangbaoTransportsAfterGate`）
- [ ] 14.5 iOS 真机：进 Home → 回探针 / 设置 version/check 仍 ✓；不杀 App 不复现 POLLUTED

## 15. POST-HOME 污染补强 + 探针 v3

- [x] 15.1 logo `HttpClient` 注册表 + `abortActiveLogoDownloads()`；`cancelLogoDownloads` 强制关闭 in-flight
- [x] 15.2 `PangbaoHomeTransportGate`：Home 挂载计数；`release` 用 `ref.exists(feedRepositoryProvider)`；token/refresh reconnect 仅 Home 挂载时
- [x] 15.3 探针 v3：**REAL** feed/ucg/logo deferred/home watch 项 + 「污染检测」+ 「释放 REAL mounts」
- [ ] 15.4 iOS 真机：REAL 项二分最小复现集；release 后进 Home 再回探针 version/check 仍 ✓

## 16. UCG provider 副作用 gate（探针定位：REAL ucgRepo 污染）

- [x] 16.1 `activateUcgHomeSession` / `deactivateUcgHomeSession`：provider 创建不 push/WS/unread；gate 后串行 unread → WS → push
- [x] 16.2 `ucgRepositoryProvider` 监听仅在 `_ucgHomeSessionActive` 时 reconnect / push / unread；wsReady baseline 去重
- [x] 16.3 Home `await mountUcgHomeTransportsIfEligible`；探针 REAL ucg 走 `activateUcgHomeSession(requireHomeMounted: false)`
- [ ] 16.4 iOS 真机：REAL ucgRepo 后污染检测 ✓；进 Home → 回探针 version/check + notify ✓

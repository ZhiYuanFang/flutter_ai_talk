## 1. Splash 冷启动路径

- [x] 1.1 修改 `app.dart` `_runColdStart`：已登录路径 `await` `eventCatalog.loadFromDisk()`、`homeHistory.loadFromDisk()`；history 有磁盘数据时将 `initialLoadDone` 置 true
- [x] 1.2 从 `_runColdStart` 移除 `await homeHistory.bootstrap()`、`await eventCatalog.bootstrap()`、`await EventLogoStartupWarmup.precacheCatalog()` 及对 `deviceNo.refresh()` 的 Splash 阻塞 await
- [x] 1.3 在 `go(/home)` 之后 `unawaited` 调用 `ColdStartBackgroundSync.run(ref)`（新建模块，见 design）

## 2. 后台 sync 与 dedupe

- [x] 2.1 新增 `bootstrap/cold_start_background_sync.dart`：顺序/并行触发 `deviceNo.refresh`、`eventCatalog.refreshFromRemote`、`homeHistory.refreshFromRemote`
- [x] 2.2 为 `EventCatalogNotifier.refreshFromRemote` 与 `HomeHistoryNotifier.refreshFromRemote` 添加 in-flight guard（复用进行中的 Future）
- [x] 2.3 精简 `HomeScreen._bootstrapHomeData`：改为调用 `ColdStartBackgroundSync` 或删除与 Splash 重复的 catalog/history bootstrap，保留 catalog 空重试 listener

## 3. Logo 异步下载与增量 state

- [x] 3.1 在 `EventCatalogNotifier` 增加 `patchEventLocalLogoPath(id, path)`，按 id 更新 state 中单项
- [x] 3.2 重构 `_downloadLogosInBackground`：有限并发池下载；每项成功调用 patch + debounced `saveToDisk`；全部完成后 `pruneLogoFiles` 与最终落盘
- [x] 3.3 必要时从 `EventCatalogStore.applyLogoDownloads` 抽取单事件 `downloadLogoIfNeeded` 供 notifier 调用

## 4. EventLogo 与 UI 联动

- [x] 4.1 修改 `EventLogo`：非 Web 在 `logoUrl` 非空但本地文件不可用时仅显示占位图，移除 `Image.network` fallback
- [x] 4.2 扩展 `HomeScreen` 的 `ref.listen(eventCatalogProvider)`：`prev.isEmpty && next.isNotEmpty` 时 `unawaited(_loadEventUsageAndButtonOrder())`
- [x] 4.3 确认历史列表、今日汇总、按钮区等已通过 `ref.watch(eventCatalogProvider)` 传递最新 definition（无需额外改动则勾选并注明）

## 5. 清理与验证

- [x] 5.1 移除 `app.dart` 对 `event_logo_startup_warmup.dart` 的阻塞引用；若无其他引用可删除该文件或保留注释说明可选后台 precache
- [x] 5.2 手工验证：新装冷启动 Splash 明显缩短；老用户有磁盘缓存时首帧有 history/catalog/本地 logo
- [x] 5.3 手工验证：弱网/离线可进主页；catalog 后台到达后按钮区填充；logo 逐个从占位换本地图
- [x] 5.4 手工验证：Web 仍走 `Image.network`；logo URL 变更时短暂占位后更新

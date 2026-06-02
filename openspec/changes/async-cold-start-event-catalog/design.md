## Context

当前 `app.dart` 的 `_runColdStart` 在已登录路径下依次 `await`：`deviceNo` 网络 refresh、`homeHistory.bootstrap()`（含远端 refresh）、`eventCatalog.bootstrap()`（含远端 refresh）、`EventLogoStartupWarmup.precacheCatalog()`，然后才 `go(/home)`。其中 logo **文件**下载（`EventCatalogStore.downloadLogo`）已在 `refreshFromRemote` 内 `unawaited`，但 Splash 仍被 **ImageCache 预热**与 **catalog/history 网络**阻塞。

`HomeScreen._init` 另通过 `_bootstrapHomeData()` 再次触发 catalog/history 远端刷新，与 Splash 路径重复。

基线 `cold-start-splash` 已要求 Splash 仅本地门禁、history/catalog 网络补全在主页之后；本设计将实现对齐并消除重复 bootstrap。

## Goals / Non-Goals

**Goals:**

- 缩短首次安装与老用户冷启动 Splash 停留时间。
- Splash 仍完成 catalog/history **磁盘 hydrate**，老用户进主页首帧有列表、有本地 logo 文件（若磁盘已有）。
- 主页展示后异步：`event/options`、logo 文件下载、history 远端 refresh；logo 落盘增量更新 UI。
- 非 Web：`EventLogo` 在本地文件未就绪时仅占位，本地就绪后自动换图。
- 单一后台 sync 入口 + in-flight guard，避免重复 API。

**Non-Goals:**

- 不改变 Web 端 logo 展示策略（仍 `Image.network`）。
- 不在 Splash 阶段恢复阻塞式全量 ImageCache precache（可选后续低优先级优化）。
- 不改变 `event/options` 接口契约或 catalog JSON 磁盘格式。
- 不改动原生 LaunchTheme / 渐变遮罩视觉。

## Decisions

### 1. Splash 阻塞边界

**决定**：已登录 Splash **await**：

- `ColdStartBootstrap.run`
- `signInChannel.restoreFromPrefs`（本地）
- `eventCatalog.loadFromDisk()`
- `homeHistory.loadFromDisk()`；若 resulting items 非空，设置 `initialLoadDone: true`

**不 await**：`deviceNo.refresh()`（网络）、`bootstrap()` / `refreshFromRemote()`、`precacheCatalog()`。

**理由**：与 `cold-start-splash` 一致；`deviceNo` 本地缓存可先用于 hydrate；网络 refresh 在主页后台补全。

**备选**：Splash 仍 await `deviceNo.refresh()` —— 拒绝，弱网仍拖 Splash。

### 2. 后台 sync 入口

**决定**：新增 `ColdStartBackgroundSync.run(WidgetRef ref)`（或等价命名），在 `go(/home)` 之后 `unawaited` 调用一次；内部顺序：

1. `deviceNo.refresh()`（若尚未有值）
2. 并行或串行：`eventCatalog.refreshFromRemote()` + `homeHistory.refreshFromRemote()`
3. logo 下载由 catalog notifier 内既有链路触发

`HomeScreen._bootstrapHomeData` 改为调用同一入口，或删除重复逻辑，仅保留 Home 特有补全（如 catalog 空重试 listener 保留）。

**In-flight guard**：`EventCatalogNotifier` / `HomeHistoryNotifier` 各维护 `_syncFuture`，并发调用复用同一 Future。

### 3. Logo 下载与 state 更新

**决定**：

- `applyLogoDownloads` 拆出单事件 `downloadLogoIfNeeded`，由 notifier 用**有限并发池**（如 6）调度。
- 每个事件成功落盘 → `patchEventLocalLogoPath(id, path)` 更新 state 中对应项 → debounced `saveToDisk`（如 300ms）。
- 全部完成后 `pruneLogoFiles` + 最终 `saveToDisk`。

**理由**：支持「占位 → 逐个换图」；避免整批替换导致 UI 长时间无 local path。

**备选**：整批完成后一次 `state = withLogos` —— 拒绝，首装体验差。

### 4. EventLogo 渲染策略

**决定**（非 Web）：

```
localLogoPath 且文件存在 → Image.file
否则 → placeholder（即使 logoUrl 非空）
```

Web 保持：`Image.network` → placeholder。

**理由**：与后台下载单一数据源一致，避免 Splash/展示双份网络拉取。

### 5. 移除 EventLogoStartupWarmup 阻塞调用

**决定**：删除 `app.dart` 对 `precacheCatalog` 的 `await`；文件可保留供可选主页后台 unawaited 本地 precache，但不写入 MUST 规格。

### 6. HomeScreen catalog 到达回调

**决定**：扩展 `ref.listen(eventCatalogProvider)`：当 `prev.isEmpty && next.isNotEmpty`，`unawaited(_loadEventUsageAndButtonOrder())`。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 首屏 history/catalog 为磁盘快照，短暂非最新 | 可接受；后台 refresh 静默更新；符合 `cold-start-splash` |
| 去掉 precache 后首 scroll 多几次 `Image.file` decode | 图标小；影响有限 |
| `loadFromDisk` 与 `_warmFromDisk` 竞态导致首帧空 catalog | Splash 显式 `await loadFromDisk` |
| 有磁盘 history 仍显示 loading | hydrate 后设 `initialLoadDone: true` |
| 重复 bootstrap | in-flight guard + 单一 `ColdStartBackgroundSync` |
| logo URL 变更后短暂占位 | 预期行为；merge 清旧 path 后等下载 |

## Migration Plan

1. 实现 notifier / Splash / EventLogo 变更。
2. 手工验证：新装、老用户有缓存、弱网、logo URL 变更、Web 不受影响。
3. 无数据库迁移；catalog JSON 格式不变。
4. 回滚：恢复 `app.dart` await bootstrap + precache。

## Open Questions

- （已关闭）Splash 是否 await `deviceNo` 网络 —— **否**，仅本地。
- 是否在主页后台 unawaited 本地 FileImage precache —— **可选**，不阻塞本 change。

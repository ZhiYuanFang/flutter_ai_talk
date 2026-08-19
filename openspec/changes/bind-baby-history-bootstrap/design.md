## Context

绑定流程（`baby_bind_screen._bind` / `_create`）在 API 成功后：

1. `ensureAccessTokenHasDeviceNoFromWidget` 对齐 JWT
2. `deviceNoNotifierProvider.setLocal`
3. `feedRepository.reconnectHistoryWebSocket(resetStrike: true)`
4. `context.pop(true)`

历史 HTTP 拉取依赖：

- 冷启动一次性 `ColdStartBackgroundSync.refreshFromRemote()`（绑定前若 `deviceNo` 为空则已拉空）
- `HomeScreen` 内 `ref.listen(deviceNoNotifierProvider)` → `_reloadHistoryIfLoggedIn()` → `bootstrap()`

主壳 `UcgHomeShell` 默认 `initialPage: HomePagerPage.prediction`，`PageView.builder` 可能不构建喂养页，`HomeScreen` 监听未注册。

`predictionRangeHistoryProvider` 仅在 `prevDn` 为空且 `nextDn` 非空时 `ensureLoaded(force: true)`，换绑 A→B 不触发。

## Goals / Non-Goals

**Goals:**

- 绑定已有宝宝（`bindwx`）或创建宝宝（`auto_save`）成功后，**不依赖 UI 页挂载**，主页历史与预测 range 历史 MUST 发起 HTTP 拉取。
- 换绑不同 `deviceNo` 时清掉旧宝宝内存列表，拉取新宝宝第一页。
- 复用现有 `bootstrap` / `refreshFromRemote` / `ensureLoaded` single-flight，不新增并行 HTTP 风暴。

**Non-Goals:**

- 不改变 Splash 阻塞策略或 `ColdStartBackgroundSync` 冷启动语义。
- 不改动 history WebSocket 建连时序（仍遵循 `history-ws-token-sync-after-bind`）。
- 不自动新建 `**/test/**` 文件。

## Decisions

### 1. Provider 层 listen `deviceNo`（主修复）

**选择：** 在 `homeHistoryProvider` 工厂内 `ref.listen(deviceNoNotifierProvider, ...)`：

- 已登录且 `nextDn` 非空
- `prevDn != nextDn`（trim 后比较，含 null/空 ↔ 非空）
- 调用 `notifier.onDeviceNoChanged()` → bump `_epoch`、清 `HomeHistoryMemoryCache`、`_warmFuture = null`、`bootstrap()`

**理由：** 与 `predictionRangeHistoryProvider` 模式一致；不依赖 `HomeScreen` 是否 build。

**备选：** 仅在 `baby_bind_screen` 显式 bootstrap —— 无法覆盖设置页等其他改 `deviceNo` 入口，否决作唯一方案；可作为双保险保留。

### 2. 换绑清盘

**选择：** `deviceNo` 变更时若 `prevDn` 非空且 `prevDn != nextDn`，先 `state = const HomeHistoryState()`（或保留 `initialLoadDone: false` 直至 bootstrap 完成），再 bootstrap，避免 `mergeRemoteHistoryAscWithPendingLocal` 把 A 的 pending/旧行 merge 进 B。

**理由：** 探索中发现换绑可能展示错误历史。

### 3. 扩展 prediction range listen

**选择：** 将条件从「仅 prev 空 → next 非空」改为「`prevDn != nextDn` 且 next 非空」。

**理由：** 预测页默认可见，range 空会导致骨架/量身定做门闸误判。

### 4. baby_bind 双保险

**选择：** `_bind` / `_create` 在 `setLocal` 与 WS reconnect 之后：

```dart
unawaited(ref.read(homeHistoryProvider.notifier).bootstrap());
unawaited(ref.read(predictionRangeHistoryProvider.notifier).ensureLoaded(force: true));
```

**理由：** 绑定页 pop 瞬间 Provider listen 与页面 dispose 时序竞态时仍保证拉取；single-flight 去重。

### 5. HomeScreen listen 处理

**选择：** 保留 `HomeScreen` 现有 listen，依赖 `bootstrap`/`refreshFromRemote` 的 `_refreshFuture` single-flight 去重；不在本 change 删除 Home 监听（最小 diff）。

**备选：** 删除 Home 监听避免冗余 —— 可后续清理，非必须。

## Risks / Trade-offs

- **[Risk] deviceNo listen 与 baby_bind 双调用重复 bootstrap** → Mitigation：`_refreshFuture` single-flight；第二次 no-op。
- **[Risk] 换绑清盘导致 UI 闪空** → Mitigation：bootstrap 先 `_warmFromDisk` 读 B 的磁盘缓存再远端；acceptable。
- **[Risk] 绑定后立即 pop，bootstrap in-flight 用户见 loading** → Mitigation：`initialLoadDone` 与现有空态一致；预测页 watch `homeHistoryProvider` 会更新。
- **[Trade-off] epoch bump 作废进行中的 loadMore** → 换绑场景可接受。

## Migration Plan

1. 实现 `HomeHistoryNotifier.onDeviceNoChanged` + provider listen。
2. 扩展 prediction range listen。
3. baby_bind 双保险调度。
4. 真机：预测页门闸绑定已有宝宝 → 返回后预测/喂养均见历史（或正确空态+可添加）。
5. 回滚：revert 单 PR。

## Open Questions

- 是否存在除 `baby_bind_screen` 外写入 `setLocal` 且需同样双保险的路径？（`remote_auth_repository` 登录带 deviceNo —— listen 应已覆盖）
- 换绑时是否需 `HomeHistoryStore.clearAll()` 或仅按新 dn 读写？（实现时按现有 per-deviceNo 文件策略）

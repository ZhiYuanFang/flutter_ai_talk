## Context

- `wipeAccountLocalState` 已清 session、`deviceNo`、`HomeHistoryStore.clearAll`、`HomeHistoryMemoryCache`、`homeHistory.clearForSignOut()`。
- `clearForSignOut` 仅 `state = 空`，不递增世代、不清 `_queuedWhileFlyFrozen`、不使 in-flight `_refreshFromRemoteImpl` 失效。
- `_refreshFromRemoteImpl` 在已登录但 `deviceNo` 为空时 `return`，**保留**当前 `items`（便于旧的 `showBindBanner` 路径，却放大串号风险）。
- 复现：切号 wipe 后登录未绑定账号 → 「请绑定宝宝」+ 旧列表。

## Goals / Non-Goals

**Goals:**

- wipe / `clearForSignOut` 之后，任何先于 wipe 启动的历史写回不得再更新 notifier。
- 已登录且无 `deviceNo` 时，home 历史 MUST 为空（全屏绑定引导，而非 banner+旧列表）。
- 保持 wipe 入口与「不清凭据历史」不变。

**Non-Goals:**

- 不扩大 wipe 到 UCG 草稿/主题等。
- 不在本变更重构整个 History WS；transports release 仍由切号流程负责。
- 不强制 invalidate 整个 `homeHistoryProvider`（可选，世代号足够则可不 dispose）。

## Decisions

### D1：世代号（epoch）作废 in-flight

- `HomeHistoryNotifier` 维护 `_epoch`（或 `_signOutGeneration`）。
- `clearForSignOut`：`_epoch++`，清飞入队列，`_warmFuture = null`，`_refreshFuture` 置空（或仅靠 epoch 丢弃结果），state 置空 + `HomeHistoryMemoryCache.clear()`。
- `_refreshFromRemoteImpl` / `setItems` / `_applyState` 在 await 之后与写 state 前比对 epoch；不匹配则丢弃。
- **备选**：`invalidate(homeHistoryProvider)` — 更重，KeepAlive 首页可能短暂闪烁；优先 epoch。

### D2：无 deviceNo 时强制空列表

- `_refreshFromRemoteImpl` / `_loadWarmFromDisk`：已登录且 dn 空 → `state = 空 + initialLoadDone`，并 clear memory；**不得** early-return 保留旧 items。
- 与产品一致：未绑定不应展示上一设备喂养。

### D3：飞入队列

- `clearForSignOut` 必须 `_queuedWhileFlyFrozen.clear()`，并视情况 `_flyAnimationFrozen = false`（避免残留冻结挡住后续合法更新）。

### D4：persist 竞态（次要）

- `persistToDisk` 在 await 前后检查 epoch 与当前 dn；wipe 后 dn 空则不写。世代丢弃 setItems 后通常不再 persist；仍建议在 save 前再读 dn。

## Risks / Trade-offs

- [Risk] epoch 漏加在某条写路径 → Mitigation：写 state 收口到 `_applyState` / `_setItemsNow`，统一校验。
- [Risk] 丢弃合法刷新 → Mitigation：仅 clearForSignOut / wipe 递增 epoch；普通 refresh 不递增。
- [Trade-off] 去掉「未绑定+非空列表」banner 路径 → 接受；未绑定应走空态引导。

## Migration Plan

纯客户端；无迁移。回滚即去掉 epoch 与空 dn 清列表逻辑。

## Open Questions

- 无阻塞项。

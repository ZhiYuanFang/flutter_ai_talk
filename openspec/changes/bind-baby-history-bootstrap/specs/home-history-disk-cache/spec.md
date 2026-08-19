## ADDED Requirements

### Requirement: deviceNo 变更 MUST 在 Provider 层触发 stale-while-revalidate
The client MUST register a global listener on `deviceNoNotifierProvider` for `homeHistoryProvider` so that any material change to the active baby ID triggers cache hydrate and remote refresh, independent of which home pager tab is visible.

客户端 MUST 在 `homeHistoryProvider` 层（而非仅 UI 页 `build`/`listen`）监听 `deviceNoNotifierProvider`；当已登录用户的 `deviceNo` 发生实质变更时，MUST 执行 stale-while-revalidate：先按新 `deviceNo` hydrate 磁盘快照（若有），再异步 `GET /device/history/api/list` 刷新；**不得**因智能预测页为默认着陆页、喂养页未构建而跳过远端拉取。

#### Scenario: 喂养页未挂载时绑定成功
- **WHEN** 用户位于 `/home` 且 PageView 当前页为智能预测，喂养页 `HomeScreen` 尚未 build
- **AND** 用户完成宝宝绑定且 `deviceNo` 从空变为非空
- **THEN** `homeHistoryProvider` MUST 仍触发 bootstrap/refreshFromRemote
- **AND** 磁盘读写 MUST 使用新 `deviceNo` 作为 cache key

#### Scenario: 与冷启动 bootstrap 不重复阻塞
- **WHEN** `deviceNo` 变更触发的 bootstrap 与 `ColdStartBackgroundSync` 或进行中的 `refreshFromRemote` 重叠
- **THEN** 客户端 MUST 通过 single-flight（如 `_refreshFuture`）合并为一次 in-flight 远端拉取
- **AND** MUST NOT 因重复监听导致连接槽占满或列表震荡

## MODIFIED Requirements

### Requirement: 后台 sync 不得重复阻塞

The system SHALL use a single background sync entry with in-flight deduplication for catalog and history remote refresh after cold start. When the user is logged in, catalog and history remote refresh MUST NOT run in unbounded parallel against the same API host; they MUST complete (serially or with bounded concurrency) before the history WebSocket connect handshake begins. 系统 MUST 通过单一后台入口（如 `ColdStartBackgroundSync`）在进主页后触发 catalog/history 远端 sync，且 MUST 用 in-flight guard 避免 Splash 与 `HomeScreen` 重复并发相同 sync。**已登录**时 catalog 与 history 远端 refresh MUST 错峰（串行或限并发），且 MUST 在历史 WebSocket 开始 handshake **之前**完成或释放对 `AppEnv.apiBaseUrl` 同 host 的连接占用。

#### Scenario: 冷启动与 Home 双路径

- **WHEN** Splash 已 `unawaited` 后台 sync 且 `HomeScreen` 初始化再次请求 sync
- **THEN** 系统 MUST 复用进行中的 Future 或跳过重复请求，不得对 `event/options` 或 history 列表发起无必要的并行重复拉取

#### Scenario: 已登录 catalog 与 history 错峰

- **WHEN** 用户已登录且 `ColdStartBackgroundSync` 触发 catalog 与 history 远端 refresh
- **THEN** 系统 MUST NOT 对 `AppEnv.apiBaseUrl` 无上限并行发起 catalog 与 history 两路 HTTP（MUST 串行或限并发 ≤2）
- **AND** 历史 WebSocket MUST NOT 在该 sync 完成前通过 `setConnectionDesired(true)` 开始新的 connect handshake

#### Scenario: 未登录仍仅 bootstrap catalog

- **WHEN** 用户未登录且进入 `/home`
- **THEN** 系统 MUST 仍仅 bootstrap event catalog（或等价游客路径）
- **AND** MUST NOT 因本变更而阻塞 notify banner 或游客 UI

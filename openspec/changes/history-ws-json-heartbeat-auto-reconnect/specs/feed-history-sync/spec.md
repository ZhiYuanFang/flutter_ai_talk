# feed-history-sync 变更规格

基线：`openspec/specs/feed-history-sync/spec.md`

## ADDED Requirements

### Requirement: 重连成功不得拉取历史 list

The client MUST NOT invoke the history list HTTP API solely because history WebSocket reconnect succeeded. 历史 WebSocket **重连成功**时，客户端**不得**因此调用 `loadHistory()`、`tryLoadHistory()` 或等价的 **`GET /device/history/api/list`** 以刷新首页列表。

#### Scenario: 自动重连就绪后不 list

- **WHEN** 历史 WebSocket 经自动重连完成 handshake 并就绪（`isHistoryWebSocketReady == true`）
- **THEN** 客户端**不得**在该重连成功路径内紧接着调用 history list HTTP
- **AND** 列表增量必须继续依赖 WebSocket `create`/`update`/`delete` 推送

#### Scenario: 手动横幅重连成功不 list

- **WHEN** 用户点击重连横幅且 handshake 成功
- **THEN** 客户端**不得**因该次手动重连成功而调用 history list HTTP
- **AND** 必须仅通过后续 WS 事件更新 `_cache`

### Requirement: 断线期间可能漏收推送事件

The system SHALL document that history WebSocket disconnect may cause the client to miss inbound create/update/delete events until the next explicit list load or new pushes after reconnect. 历史 WebSocket **断线期间**，客户端**可能漏收**服务端下发的 `create`/`update`/`delete` 事件；重连成功后**不得**以 HTTP list 自动补偿，除非用户触发其它已存在的显式 list 路径（如首屏初始化）。

#### Scenario: 断线漏 create 不重连 list 补偿

- **WHEN** 客户端在断线期间服务端已推送一条 `create` 事件而客户端未收到
- **AND** 随后 WebSocket 重连成功
- **THEN** 客户端**不得**仅因重连成功而自动 list 拉取以填补该条
- **AND** 本地列表可能与服务端存在缺口，直至用户触发允许的 list 路径或收到新的 WS 事件

## MODIFIED Requirements

### Requirement: WebSocket 增量为写后读的主路径

The system SHALL treat history WebSocket events as the primary mechanism to reflect new or updated history records on the home list after a chat write and after reconnect, without HTTP list refresh on reconnect success. 在 `watchLatest()` 已订阅且 WebSocket 已就绪的前提下，服务端持久化后的推送事件必须能反映到首页列表；**重连成功后的增量同样仅依赖 WS**，**不得**在重连成功时以 HTTP list 刷新作为补偿。

#### Scenario: 服务端推送 create 后首页出现新条

- **WHEN** 服务端经历史 WebSocket 下发一条可被解析为新建记录的 payload（例如 `action` 为 `create` 或等价结构）
- **THEN** 客户端必须将该记录合并进本地历史展示
- **AND** 不得依赖「刚完成的 sendCommand」后的 HTTP list 刷新作为唯一手段

#### Scenario: 重连后就绪仍走 WS 增量

- **WHEN** 历史 WebSocket 在断线后重连并就绪
- **AND** 服务端随后推送 `update` 或 `create`
- **THEN** 客户端必须通过 `_mergeInbound`（或等价）更新展示
- **AND** **不得**在重连成功瞬间调用 list HTTP 替代 WS 增量

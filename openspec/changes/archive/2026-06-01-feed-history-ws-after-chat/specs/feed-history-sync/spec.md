## ADDED Requirements

### Requirement: 聊天发送成功后不得立即拉取历史 list

The client MUST NOT invoke the history list HTTP API (`GET /device/history/api/list` or equivalent `loadHistory`) solely as a consequence of a successful `sendCommand` / chat submit for the purpose of refreshing the home history list. 客户端在用户成功提交聊天（`sendCommand` 正常返回）后，不得再自动调用 `loadHistory()` 以刷新首页历史列表；列表增量须依赖已建立的历史 WebSocket 推送（`create`/`update`/`delete` 等）更新本地缓存与 UI。

#### Scenario: 语音或 Web 文本发送成功后不触发 list

- **WHEN** 首页完成一次 `sendCommand` 且未抛出业务错误  
- **THEN** 客户端不得在本次交互流程内紧接着调用 `loadHistory()`（或等价的 history list GET）用于更新首页列表

#### Scenario: 首次进入首页仍可种子加载

- **WHEN** 用户打开首页且需要展示历史列表的初始化流程（例如 `initState` 中的首次加载）  
- **THEN** 客户端仍允许调用 `loadHistory()` 以获取初始快照（与本需求「发消息后不刷」不冲突）

### Requirement: WebSocket 增量为写后读的主路径

The system SHALL treat history WebSocket events as the primary mechanism to reflect new or updated history records on the home list after a chat write. 在 `watchLatest()` 已订阅且 WebSocket 已发送鉴权首帧的前提下，服务端在持久化聊天相关历史记录后推送的事件必须能被客户端现有解析逻辑消费并反映到首页列表（合并或追加 `_cache` 并通知监听方）。

#### Scenario: 服务端推送 create 后首页出现新条

- **WHEN** 服务端经历史 WebSocket 下发一条可被解析为新建记录的 payload（例如 `action` 为 `create` 或等价结构）  
- **THEN** 客户端必须将该记录合并进本地历史展示，且不得依赖「刚完成的 sendCommand」后的 HTTP list 刷新作为唯一手段

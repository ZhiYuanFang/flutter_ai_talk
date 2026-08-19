## ADDED Requirements

### Requirement: 宝宝绑定或切换成功后 MUST 触发 HTTP 历史 bootstrap
After a successful baby bind or create (`bindwx` / `auto_save`) or any persisted `deviceNo` change while logged in, the client MUST trigger home history HTTP bootstrap without requiring the feeding `HomeScreen` widget to be mounted.

宝宝 ID 绑定或切换成功且用户已登录时，客户端**必须**触发主页历史的 HTTP bootstrap（`bootstrap` 或等价的 disk hydrate + `refreshFromRemote`），**不得**仅依赖历史 WebSocket 重连回填列表；**不得**依赖喂养页 `HomeScreen` 已挂载才注册监听。

#### Scenario: 预测页门闸绑定已有宝宝
- **WHEN** 用户在智能预测主页（默认着陆）通过绑定门闸进入绑定页，成功 `bindwx` 已有宝宝 ID 并返回
- **THEN** 客户端 MUST 在 `deviceNoNotifierProvider` 更新后发起主页历史 HTTP 拉取
- **AND** `homeHistoryProvider` MUST 反映该宝宝的远端第一页或等价的合并结果（含磁盘缓存 hydrate）
- **AND** MUST NOT 长期保持绑定前空列表或上一宝宝残留列表

#### Scenario: 换绑至不同已有宝宝
- **WHEN** 用户已将本地 `deviceNo` 从 A 绑定/切换为 B（A 非空且 A ≠ B）
- **THEN** 客户端 MUST 作废针对 A 的 in-flight 主页历史加载
- **AND** MUST 拉取 B 对应的历史列表
- **AND** MUST NOT 将 A 的记录 merge 展示为 B 的历史

#### Scenario: 绑定成功仍执行 WS 重连
- **WHEN** 绑定流程在 HTTP bootstrap 之前或并行执行 history WebSocket reconnect
- **THEN** HTTP bootstrap MUST 仍独立执行
- **AND** token 对齐与 WS 行为 MUST 继续符合 `history-ws-token-sync-after-bind` 基线

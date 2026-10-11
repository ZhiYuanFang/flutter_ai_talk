## ADDED Requirements

### Requirement: 未连接绑定 MUST 可手动重连

When a binding row reports `connected=false`, the client MUST present a reconnect affordance. On user confirm/tap, the client MUST call `POST /device/app/api/xiaozhi-mcp/bindings/{id}/reconnect` with the authenticated App session. On success, the client MUST notify the user that reconnect was triggered and MUST refresh the bindings list. Success MUST NOT be interpreted as immediate `connected=true`. When `connected=true`, the client MUST NOT require showing the reconnect affordance. 未连接绑定 **必须** 提供重连入口并调用 go reconnect API；成功仅表示已触发，**不得** 假定立刻已连接；已连接 **不得** 强制展示重连。

#### Scenario: 未连接显示重连

- **WHEN** 绑定列表项 `connected=false`
- **THEN** UI MUST 展示可点击的「重连」入口

#### Scenario: 点击触发 API 并刷新

- **WHEN** 用户点击某绑定的「重连」且请求成功
- **THEN** 客户端 MUST 调用 `POST /device/app/api/xiaozhi-mcp/bindings/{id}/reconnect`
- **AND** MUST 提示已触发重连
- **AND** MUST 刷新绑定列表

#### Scenario: 已连接无重连入口

- **WHEN** 绑定列表项 `connected=true`
- **THEN** UI MUST NOT 展示「重连」作为必要操作（可不渲染该按钮）

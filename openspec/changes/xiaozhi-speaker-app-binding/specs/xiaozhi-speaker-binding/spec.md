## ADDED Requirements

### Requirement: 小智音箱绑定管理页

The client SHALL provide a logged-in「小智音箱」management screen that lists the current user's Xiaozhi MCP bindings and supports add, rename alias, and delete. The client MUST call gateway App APIs under `/device/app/api/xiaozhi-mcp/bindings` and MUST NOT connect directly to `xiaozhi-mcp-service`. 客户端 **必须** 提供已登录「小智音箱」管理页，经 gateway 完成绑定列表与增删改，**不得**直连 mcp 服务。

#### Scenario: 进页加载列表

- **WHEN** 已登录用户打开小智音箱管理页
- **THEN** 客户端 MUST 请求绑定列表并展示每条的备注、脱敏 token、音箱 MAC
- **AND** 响应 MUST NOT 在 UI 中展示完整 mcpToken 明文（添加表单提交前输入除外）

#### Scenario: 连接态绿红灯

- **WHEN** 列表项 `connected` 为 true
- **THEN** 客户端 MUST 以「已连接」视觉（如绿灯）展示
- **WHEN** `connected` 为 false 或字段缺失按未连接处理
- **THEN** 客户端 MUST 以「未连接」视觉（如红灯）展示，且 MUST NOT 引入第三态黄灯

#### Scenario: 改备注与删除

- **WHEN** 用户更新某条自有绑定的备注或删除该绑定
- **THEN** 客户端 MUST 分别调用 PUT alias / DELETE 接口
- **AND** 成功后 MUST 刷新或更新列表

### Requirement: 添加绑定必填字段与落点

When adding a binding, the client MUST submit non-empty `alias`, `speakerMac`, and `mcpToken` to `POST /device/app/api/xiaozhi-mcp/bindings`. The client MUST NOT send a client-chosen `deviceNo`; feeding device fallthrough MUST remain server-derived. 添加时 **必须** 提交备注、MAC、mcpToken；**不得**由客户端指定他人 deviceNo。

#### Scenario: 成功添加

- **WHEN** 用户已具备添加资格（已开通或试用可用）、已绑宝宝，并提交合法三字段
- **THEN** 客户端 MUST POST 绑定并在成功后刷新列表

#### Scenario: 未绑宝宝禁止添加

- **WHEN** 当前账号未绑定宝宝设备
- **THEN** 客户端 MUST 禁用或拒绝添加，并引导前往绑机流程
- **AND** MUST NOT 在未绑机时成功发出添加请求（或发出后仅展示服务端错误且不假装成功）

### Requirement: 同 MAC 再添加视为更新

The client SHALL treat re-submitting the same speaker MAC as a save that may update the token on the server (upsert). After success the client MUST refresh the list so the user sees a single row for that MAC. 同 MAC 再提交视为服务端可更新 token；成功后 **必须** 刷新列表，同一 MAC 仍为一条。

#### Scenario: 换密后列表仍一条

- **WHEN** 用户对已存在的音箱 MAC 再次提交新的 mcpToken（及备注）且服务端成功
- **THEN** 客户端 MUST 刷新列表且该 MAC 不得因客户端逻辑被展示为两条

## ADDED Requirements

### Requirement: HTTP 响应 JSON 外壳

The client and server SHALL use a unified JSON envelope for REST responses: top-level keys `code` (int), `message` (string), and `data` (object or null). 所有约定中的「请求体 / 响应体字段」均指 **`data` 内** 的 JSON（除非显式写明顶层字段）。服务端 **HTTP 状态码必须为 200**（网络栈仍可能产生非 200，客户端按异常处理）。

#### Scenario: 业务成功

- **WHEN** 服务端返回 `code` 为 `0` 且 `data` 非空（或成功分支允许的空对象）
- **THEN** 客户端必须按各接口契约解析 `data` 并继续业务流程

#### Scenario: 业务失败

- **WHEN** 服务端返回 `code` 非 `0`
- **THEN** 客户端必须使用 **`message`** 作为用户可见文案通过 **Toast** 提示，且不得将失败误判为成功

### Requirement: 失败时 data 可为 null

The server MAY set `data` to null when `code` is non-zero; the client MUST tolerate null `data` and MUST NOT assume `data` is always an object. 当 `data` 为 `null` 时，用户可见失败原因仍 **仅依赖 `message`**，并以 Toast 展示。

#### Scenario: data 为 null 的 Toast

- **WHEN** 响应为 `{"code":1,"message":"设备未绑定","data":null}`
- **THEN** 客户端必须弹出 Toast 显示「设备未绑定」且不得访问 `data` 的子字段

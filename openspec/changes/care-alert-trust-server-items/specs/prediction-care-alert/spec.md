## ADDED Requirements

### Requirement: Feeding care-alert list SHALL trust server snapshot items without local day-key expiry

After a successful care-alert daily snapshot is applied to client state (SSE `result` or non-force GET latest hydrate), the feeding workspace list derived for display MUST expose that snapshot's `items` whenever state is `ready`, not `loading`, and not `failed`. The client MUST NOT hide or empty that list solely because a local Shanghai calendar day key differs from the server's `day` field (or from any client-stored `dayKey` metadata). Server `day` MAY be retained for logging or diagnostics but MUST NOT gate list visibility. 喂养分析列表在快照成功写入且非加载/失败时 **必须** 展示服务端 `items`；**不得** 仅因本地日键与服务端 `day`/`dayKey` 不一致而清空列表。

#### Scenario: SSE result shows list immediately

- **WHEN** 用户在喂养工作台完成「AI智能分析」且流式 `result` 已成功写入含非空 `items` 的快照
- **THEN** 客户端 MUST 在同一会话内展示这些 items（思考区可已清空）
- **AND** MUST NOT 要求用户退出并重新进入页面才能看到列表
- **AND** MUST NOT 因服务端 `day` 含时分或与今日 `YYYY-MM-DD` 字符串不等而返回空列表

#### Scenario: Hydrate and stream share display gate

- **WHEN** 同一 `ready` 快照既可来自 GET latest hydrate，也可来自 SSE result
- **THEN** 两者 MUST 使用同一套展示门闩（ready / not loading / not failed）
- **AND** MUST NOT 对其中一条路径额外施加本地日键过期过滤

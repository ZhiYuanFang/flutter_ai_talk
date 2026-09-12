## ADDED Requirements

### Requirement: Effective unlock side-effect paths SHALL await VIP settlement

When computing effective catalog unlock as `item.unlocked || isVip` on a side-effect ensure or automatic refresh path that may skip or trigger further HTTP, the client MUST obtain `isVip` only after awaiting the shared VIP settlement API (or equivalent single-flight). The client MUST NOT use a loading/unset VIP Async value as `isVip=false` for that side-effect decision. UI surfaces that only render unlock chrome MAY watch VIP asynchronously, but MUST NOT introduce per-screen duplicate settlement protocols that bypass the shared API when they also fire gated side effects.

在副作用 ensure/自动刷新路径上以 `unlocked || isVip` 计算有效开通并可能跳过或触发后续 HTTP 时，客户端 **必须** 仅在 await 共享 VIP settle 之后取得 `isVip`；**不得** 把 loading/未设置 Async 当作该决策上的 `isVip=false`。仅渲染开通态的 UI **可以** 异步 watch，但若同时发门闸副作用则 **不得** 绕过共享 API 另搞一套 per-screen settle。

#### Scenario: catalog 未开通且 VIP settle 为真

- **WHEN** 某 catalog 项 `unlocked=false` 且 VIP settle 结果 `isVip=true`
- **THEN** 副作用路径 MUST 将该项视为有效开通（`isFeatureEffectivelyUnlocked` 或等价）
- **AND** MUST NOT 因 settle 前的短暂 loading 永久跳过本应发起的下游请求

#### Scenario: 新功能复用同一 settle

- **WHEN** 后续变更新增另一依赖 `isVip` 的副作用门闸
- **THEN** 该门闸 MUST 复用共享 VIP settle API
- **AND** MUST NOT 仅复制预测页或开通中心的页面级 await 而不走共享 API

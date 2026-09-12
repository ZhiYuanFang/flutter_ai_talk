## ADDED Requirements

### Requirement: Care-alert daily ensure SHALL await VIP settlement before unlock gate

Before the care-alert daily ensure evaluates whether「值得留意」is effectively unlocked via catalog item and/or `isVip` and before it skips or issues `GET /device/api/care-alert/daily`, the client MUST await the shared VIP settlement API (or equivalent). The client MUST NOT skip the daily fetch solely because VIP Async state was still loading/unset at ensure start when a subsequent settled `isVip=true` would have unlocked the feature. After VIP settlement reports non-VIP and the catalog item is not unlocked, the client MAY skip daily as today. Eligibility (`care-alert/eligibility`) ordering relative to VIP settle MUST keep cash feeding qualification semantics; VIP settlement MUST run before the unlock gate that gates daily.

在 care-alert 日列表 ensure 按 catalog/`isVip` 判定有效开通、并决定跳过或请求 `GET /device/api/care-alert/daily` 之前，客户端 **必须** await 共享 VIP settle。**不得** 仅因 ensure 开始时 VIP 仍 loading/未设置且随后 settled 为 VIP 本应开通，而永久跳过 daily。settle 为非 VIP 且 catalog 未开通时 **可以** 按现逻辑跳过。喂养资格 eligibility 语义保持；VIP settle **必须** 发生在闸住 daily 的开通门闸之前。

#### Scenario: VIP 覆盖值得留意时拉 daily

- **WHEN** 用户已登录且 feeding eligibility 合格，catalog 该项未 `unlocked`，但 VIP settle 为 `isVip=true`
- **THEN** care-alert ensure MUST 在开通门闸通过后发起（或复用）daily 拉取
- **AND** MUST NOT 因 VIP 曾短暂未 settled 而停留在「未开通跳过」且无后续自动补拉

#### Scenario: 非 VIP 且未开通仍跳过

- **WHEN** VIP settle 为非 VIP 且值得留意 catalog 未开通
- **THEN** 客户端 MUST NOT 因本变更而强制请求 daily

## MODIFIED Requirements

### Requirement: Growth trajectory UI SHALL be reachable from AI analysis hub after unlock

The growth-trajectory prediction session UI (latest result, predict/restart, thinking, Q&A, Markdown result, usage copy) SHALL be presented on a dedicated workspace route opened from the AI analysis hub after the capability is effectively unlocked. The hub growth card SHALL offer unlock when locked and SHALL navigate to the workspace when unlocked. The hub MUST NOT call growth-trajectory `ensureLatest` solely because the user opened the hub. 成长轨迹预测会话 UI **必须** 在 Hub 有效开通后进入的独立工作台展示；Hub 成长卡未开通时 **必须** 提供开通，已开通时 **必须** 可进入工作台；**不得** 仅因打开 Hub 调用 `ensureLatest`。

#### Scenario: 未开通停在 Hub

- **WHEN** 用户非 VIP 且成长轨迹未解锁
- **THEN** Hub 成长卡 MUST 提供邀请/支付等开通路径（与既有规则一致）
- **AND** MUST NOT 进入可发起 turn SSE 的工作台主流程

#### Scenario: 已开通进子页再拉历史

- **WHEN** 用户已有效开通成长轨迹
- **AND** 从 Hub 进入成长工作台
- **THEN** 工作台 MAY/MUST 按需 `ensureLatest` 展示历史结果
- **AND** 用户仅停留 Hub 时客户端 MUST NOT 因此强制 `ensureLatest`

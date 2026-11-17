## ADDED Requirements

### Requirement: Capability card SHALL show syncing copy until entitlement settle is ready

While predict entitlement settle phase is syncing, the prediction-capability status card MUST show title copy「正在同步能力中」（or equivalent）and MUST NOT yet apply the ready-phase priority labels（pro / basic / VIP / 基础版待开通 / 固定间隔）. When phase becomes ready, the card MUST update in place to the existing priority copy without remounting the prediction page route. Tapping the card MAY still navigate to the unlock hub during syncing.

能力卡在 syncing MUST 显示「正在同步能力中」；ready 后 MUST 就地切换为档位文案；MUST NOT 为此重挂预测页路由。

#### Scenario: 同步中占位

- **WHEN** 用户打开已绑定预测页且开通相位为 syncing
- **THEN** 能力卡 MUST 展示「正在同步能力中」
- **AND** MUST NOT 在此时展示「固定间隔」或「基础版待开通」作为最终态文案

#### Scenario: settle 后就地更新

- **WHEN** 相位从 syncing 变为 ready 且用户为 VIP
- **THEN** 能力卡 MUST 更新为 VIP/最高档覆盖类文案（按既有优先级）
- **AND** 预测页路由 MUST NOT 因该更新而 dispose 重建

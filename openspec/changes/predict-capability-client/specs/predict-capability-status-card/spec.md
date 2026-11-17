## ADDED Requirements

### Requirement: Smart prediction page SHALL show a capability status card between next-three-hours and the event list

On the bound (non auth-guest) smart prediction page, between the「接下来3小时」block and the prediction event list (or demo skeleton list), the client SHALL render a prediction-capability status card. Tapping the card MUST navigate to the feature unlock hub (MAY scroll/highlight predict capability items when supported). Auth cold guest chrome without bound baby MUST NOT require this card.

已绑定预测页 MUST 在 3 小时与列表之间展示能力卡；点击 MUST 进开通页。

#### Scenario: 位置

- **WHEN** 用户打开已绑定智能预测页
- **THEN** UI MUST 在接下来3小时下方、事件预测列表上方展示能力卡

### Requirement: Capability card copy SHALL reflect entitlement and algorithm readiness

The card MUST show the current capability type and expiry when applicable, using this priority:

1. Effective `predict_capability_pro` → Pro 文案 + 到期信息  
2. Else effective `predict_capability_basic` → 基础版文案 + 到期信息  
3. Else isVip → VIP 覆盖预测推送类文案（MUST NOT claim a paid feature row）  
4. Else silent rail has ≥1 affinity-ready root →「基础版待开通」  
5. Else →「固定间隔」

能力卡文案 MUST 按 pro→basic→VIP→基础版待开通→固定间隔优先级。

#### Scenario: 有算法根未开通

- **WHEN** 用户未 entitle，且静默轨至少一根亲和可产出 nextAt
- **THEN** 能力卡 MUST 展示「基础版待开通」（或等价产品文案）
- **AND** MUST NOT 仅显示「固定间隔」而忽略算法已就绪

#### Scenario: 基础版到期日

- **WHEN** basic unlocked 且 expiresAt>0
- **THEN** 能力卡 MUST 展示剩余天数或到期语义

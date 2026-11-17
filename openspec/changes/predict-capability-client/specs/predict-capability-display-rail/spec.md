## ADDED Requirements

### Requirement: Client SHALL split prediction into display rail and silent affinity rail

The Flutter client SHALL maintain two logical prediction rails. The **silent rail** MUST always compute per-root next occurrence using the affinity-weighted interval algorithm (with seed interval only as fallback when affinity cannot produce a median), and MUST feed predict-imminent pending upload. The **display rail** MUST drive user-visible prediction surfaces. When predict display entitlement is inactive, the display rail MUST force seed-interval nextAt for roots that have a valid recall seed (≥15 minutes) and a real lastAt, and MUST NOT show affinity-winning nextAt on those surfaces. When predict display entitlement is active, the display rail MUST use the same nextAt as the silent affinity result for that root.

客户端 MUST 拆分展示轨与静默亲和轨；静默轨 MUST 始终亲和计算并供给 imminent 上传；未 entitle 时展示轨 MUST 强制种子间隔；已 entitle 时展示 MUST 与静默一致。

#### Scenario: 未开通时卡上为种子、pending 为亲和

- **WHEN** 用户无 basic/pro 有效人权益且非 VIP，根 A 有有效种子且亲和亦可算出 nextAt_algo ≠ nextAt_seed
- **THEN** 预测卡 / tip / 接下来3小时 / 小组件 MUST 展示 nextAt_seed
- **AND** `PUT .../predict/imminent/pending` 中 A 的 nextAt MUST 为 nextAt_algo（或静默轨对该根的权威值）

#### Scenario: 开通后展示与静默一致

- **WHEN** 用户 basic 或 pro 人权益未过期，或 isVip=true
- **THEN** 上述展示面 MUST 使用静默亲和轨 nextAt
- **AND** MUST NOT 再强制覆盖为种子间隔

### Requirement: Predict display entitlement SHALL be basic OR pro OR VIP

Predict display entitlement MUST be true when any of: catalog item `predict_capability_basic` is effectively time-valid unlocked; catalog item `predict_capability_pro` is effectively time-valid unlocked; or settled `isVip` is true. The client MUST NOT require catalog `unlocked=true` solely because the user is VIP (Go may leave unlocked false). Expiry of basic/pro without VIP MUST turn display entitlement false and return display rail to seed forcing while silent rail continues.

展示覆盖 MUST = basic∨pro∨VIP；VIP MUST 不依赖 catalog 改写 unlocked；到期无 VIP MUST 回种子展示且静默继续。

#### Scenario: VIP 无功能行仍 entitle 展示

- **WHEN** isVip=true 且 basic/pro catalog unlocked=false
- **THEN** 展示轨 MUST 按已 entitle 使用亲和 nextAt
- **AND** MUST NOT 弹出「基础版已生效」首次提醒窗

#### Scenario: 试用到期回退展示

- **WHEN** basic 权益 expiresAt 已过且非 VIP、无 pro
- **THEN** 展示轨 MUST 强制种子间隔（有种子的根）
- **AND** 静默亲和 MUST 继续计算并可上传 pending

### Requirement: Widget tip and next-three-hours SHALL follow display rail

Home feeding tip, the smart-prediction「接下来3小时」timeline body, and desktop/home widget prediction times MUST all consume the display rail nextAt values, not a parallel affinity-only path.

喂养 tip、接下来3小时、小组件 MUST 一律跟展示轨。

#### Scenario: 未开通小组件与卡一致

- **WHEN** 展示轨对根 A 使用种子 nextAt
- **THEN** 桌面小组件与喂养 tip（若选中 A）MUST 展示同一种子 nextAt 语义
- **AND** MUST NOT 单独展示亲和 nextAt

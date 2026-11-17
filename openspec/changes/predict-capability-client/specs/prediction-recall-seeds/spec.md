## ADDED Requirements

### Requirement: Different roots SHALL allow seed interval and affinity prediction to coexist

The client SHALL evaluate recall-seed retention and affinity readiness **per catalog root**. Affinity becoming ready on root B MUST NOT clear or invalidate root A’s seed, and MUST NOT prevent root A from displaying a seed-based nextAt when the display rail requires seeds.

不同事件根 MUST 可同时存在固定间隔种子与亲和算法预测；B 达标 MUST NOT 破坏 A 的种子展示。

#### Scenario: A 种子 B 算法

- **WHEN** 根 B 亲和可产出 nextAt，根 A 仅有有效种子且亲和尚不可产出
- **THEN** A 的种子 MUST 仍保留（在展示未 entitle 或 A 仍依赖种子时）
- **AND** A 的展示轨 MUST 能给出种子 nextAt（有 lastAt 时）
- **AND** MUST NOT 因 B 就绪而让 A 长期停在「补充大概多久一次」且无 pred

### Requirement: Display-unentitled clients SHALL retain seeds needed for display rail

While predict display entitlement is inactive, the client MUST NOT discard a root’s recall seed solely because raw real-history interval sample counts meet a predictor sample gate, if that root still needs the seed interval for the display rail. Silent affinity MAY continue for that root without deleting the seed.

未 entitle 时 MUST NOT 仅因原始样本达标就丢仍需展示的种子。

#### Scenario: 亲和静默成功仍留种子

- **WHEN** 用户未 entitle，根 A 有种子，且静默亲和已能产出 A 的 nextAt
- **THEN** A 的种子 MUST 仍可用于展示轨强制间隔
- **AND** MUST NOT 被自动清除导致展示无 pred

## MODIFIED Requirements

### Requirement: Real history catching up SHALL discard that root seed immediately

When predict display entitlement is **active** and the silent affinity path for a root can produce a nextAt without needing that root’s recall seed interval, the client MUST delete that root’s recall seed and MUST stop using the seed interval for that root on both rails. The client MUST NOT discard a seed merely because a raw (pre-affinity) sample-count gate is met while affinity cannot yet produce nextAt. When display entitlement is inactive, seed discard MUST follow the retention rules above (empty real lastAt rules MAY still remove seeds).

已 entitle 且该根静默亲和可独立产出 nextAt 时 MUST 删除该根种子；MUST NOT 仅因原始样本门槛达标、亲和尚未可产出就删种；未 entitle 时 MUST 按展示保留规则处理。

#### Scenario: 已开通且亲和可独立预测则丢种子

- **WHEN** 用户已 entitle，根 A 曾有种子，且静默亲和不依赖种子即可产出 A 的 nextAt
- **THEN** A 的种子 MUST 被删除
- **AND** 后续 A 的预测 MUST 仅使用真历史亲和路径

#### Scenario: 原始样本达标但亲和不足不得丢

- **WHEN** 根 A 原始间隔样本数达到旧门槛，但亲和有效样本不足以致无法产出 nextAt，且仍存在有效种子
- **THEN** 客户端 MUST NOT 删除 A 的种子
- **AND** 展示轨（未 entitle）或静默 fallback MUST 仍可使用该种子间隔

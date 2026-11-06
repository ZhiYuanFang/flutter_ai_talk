## ADDED Requirements

### Requirement: Client SHALL re-predict from a persisted missAnchor after overdue skip

When a non-appointment catalog root has a persisted local `missAnchor` instant for the current device/baby context, interval prediction for that root MUST use `missAnchor` as the time-of-day affinity anchor (circular clock distance for weighting inter-occurrence samples) and MUST compute candidate `nextAt` as `missAnchor + interval`, where `interval` follows the existing affinity-weighted median or recall-seed rules. The prediction’s displayed true `lastAt` MUST remain the real latest occurrence tip (window or cache) and MUST NOT be replaced by `missAnchor`. Real occurrence times used for the histogram density guard MUST NOT include `missAnchor`. When no `missAnchor` is persisted, behavior MUST match the existing affinity + guard path anchored on the true `lastAt`. The client MUST NOT synthesize a feeding `HistoryRecord` for the miss. Appointment roots MUST ignore `missAnchor`.

非预约根在本机存在持久化 `missAnchor` 时，间隔预测 MUST 以 `missAnchor` 为钟点亲和锚，且候选 `nextAt` MUST 为 `missAnchor + interval`（`interval` 仍按既有亲和加权中位或回忆种子）。展示用真 `lastAt` MUST 仍为真最新发生 tip，MUST NOT 换成 `missAnchor`。直方图密度 MUST NOT 计入 `missAnchor`。无 `missAnchor` 时 MUST 保持以真 `lastAt` 为锚的既有路径。MUST NOT 为错过点合成喂养历史。预约根 MUST 忽略 `missAnchor`。

#### Scenario: 有 missAnchor 时从错过点加间隔

- **WHEN** 某非预约根存在 `missAnchor=N`，且亲和有效样本足以算出 `interval`
- **THEN** 候选 `nextAt` MUST 为 `N + interval`
- **AND** 返回/展示的真 `lastAt` MUST 仍为真发生 tip（≠ N，除非 tip 碰巧等于 N）

#### Scenario: 亲和锚使用 missAnchor 钟点

- **WHEN** 存在 `missAnchor`
- **THEN** 间隔样本的钟点亲和 MUST 相对 `missAnchor` 的本地钟点计算，MUST NOT 仅相对真 `lastAt` 钟点（当二者钟点不同时）

#### Scenario: missAnchor 不进直方图

- **WHEN** 存在 `missAnchor` 且启用密度护栏
- **THEN** 构建直方图的发生序列 MUST NOT 包含 `missAnchor`

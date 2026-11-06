## MODIFIED Requirements

### Requirement: Client SHALL guard nextAt with a per-root historical time-of-day histogram

After a candidate `nextAt` is computed for a non-appointment catalog root (from affinity-weighted median or seed interval), when the root has at least a configured minimum number of real historical occurrences (default **7**) usable for density, the client MUST evaluate the local clock time of `nextAt` against a **circular daily histogram** built from that root’s real occurrence clock times (same occurrence instant rules as interval prediction; excluding recall-seed synthetics). The histogram MUST use fixed-width bins covering 24 local hours (default **30-minute** bins). The client MAY smooth each bin with its circular neighbors. The client MUST compute a relative score of the bin containing `nextAt` (after optional smoothing) divided by the maximum bin score on that root. When the relative score is below a configured threshold (default **0.2**), that candidate is a **cold** candidate. The client MUST prefer candidates in this order, accepting the first whose relative score meets the threshold (**hot**): (1) primary median or seed `nextAt`; (2) when primary was from affinity median (not seed-only), weighted median of affinity-eligible samples whose duration is ≥ the primary median, when at least 2 such samples exist; (3) weighted median of affinity-eligible samples that cross a local calendar day boundary, when at least 2 such samples exist. When a hot candidate is accepted, the prediction MUST NOT be marked time-of-day low-confidence. When **no** hot candidate exists, the client MUST still keep a `nextAt`: for affinity paths MUST keep the **primary** median candidate; for seed-only paths MUST keep the seed-derived `nextAt`; and MUST mark the prediction as time-of-day low-confidence. The client MUST NOT return unpredictable solely because all evaluated candidates are cold. When the root has fewer than the minimum occurrences for density, the client MUST NOT apply this guard (MUST NOT mark low-confidence solely for density). The client MUST NOT use a globally hard-coded clock cutoff such as 「after 20:00」to implement this guard.

非预约根在得出候选 `nextAt`（亲和中位或种子间隔）后，当该根可用于密度的真发生次数不少于配置下限（默认 7）时，客户端 MUST 用该根真发生本地钟点构建**环形日直方图**（默认 30 分钟一格，MAY 邻格平滑；发生时刻规则与间隔预测一致，排除回忆种子），并计算 `nextAt` 所在格相对峰值的比值；低于阈值（默认 0.2）视为**冷**候选。客户端 MUST 按序优先采纳**第一个热区**候选：（1）主中位或种子；（2）非纯种子时，亲和有效且时长 ≥ 主中位的样本中位（≥2 条）；（3）亲和有效且跨本地自然日的样本中位（≥2 条）。采纳热区时 MUST NOT 标记钟点把握不足。若无一热区候选，MUST 仍保留 `nextAt`：亲和路径 MUST 保留**主中位**候选；纯种子路径 MUST 保留种子 `nextAt`；并 MUST 标记钟点把握不足。MUST NOT 仅因候选皆冷而不可预测。发生次数不足下限时 MUST NOT 启用本护栏（MUST NOT 仅因此标记把握不足）。MUST NOT 用全局写死钟点（如「20:00 后」）实现本护栏。

#### Scenario: 冷区主候选被跳过且跨日热区胜出

- **WHEN** 主中位 `nextAt` 相对峰值 &lt; 阈值，且亲和有效样本中存在不少于 2 条跨本地自然日的间隔，其加权中位对应的 `nextAt` 相对峰值 ≥ 阈值
- **THEN** 客户端 MUST 采用该跨日热区候选
- **AND** MUST NOT 标记钟点把握不足
- **AND** MUST NOT 因全局写死「20 点后」规则而拒绝（仅因该根直方图）

#### Scenario: 主候选热区直接采用

- **WHEN** 主中位或种子算出的 `nextAt` 相对峰值 ≥ 阈值，且该根真发生数 ≥ 密度下限
- **THEN** 客户端 MUST 采用该候选
- **AND** MUST NOT 标记钟点把握不足

#### Scenario: 皆冷时保留主候选并标记把握不足

- **WHEN** 主候选与设计允许的回退候选均未达到相对峰值阈值（皆冷），且该根真发生数 ≥ 密度下限
- **THEN** 客户端 MUST 保留主中位（或纯种子路径的种子）`nextAt`
- **AND** MUST 标记该预测为钟点把握不足
- **AND** MUST NOT 仅因此将该根标为不可预测

#### Scenario: 样本过少不启用护栏

- **WHEN** 某根真发生次数低于密度下限
- **THEN** 客户端 MUST NOT 仅因直方图相对峰值而拒绝或标记钟点把握不足

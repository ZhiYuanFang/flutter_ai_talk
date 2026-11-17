## ADDED Requirements

### Requirement: Next-predict glass card SHALL use post-chase live nextAt only

The feeding-home next-predict glass card MUST select its nearest prediction from live per-root predictions **after** missed-cycle chase（when applicable）. When chase yields no `nextAt` for a root, that root MUST NOT contribute a displayable next prediction. Prompt states A/B/C MUST use the final displayed `nextAt` only.

喂养下一次玻璃卡 MUST 使用漏记追赶后的 live nextAt；追赶后无 nextAt 的根 MUST NOT 入选；A/B/C MUST 仅相对终显 nextAt。

#### Scenario: 追赶失败不展示卡

- **WHEN** 某根经漏记追赶后无 nextAt，且无其它可展示最近预测
- **THEN** 喂养页 MUST NOT 渲染下一次预测玻璃卡

### Requirement: Next-predict glass card MUST NOT show missed-cycle tip chrome

The feeding-home next-predict glass card MUST NOT render the `可能漏记：…` missed-tip row even when the selected live prediction carries a non-empty tip list. Missed-tip chrome is limited to portrait smart prediction cards per `smart-prediction-page`.

喂养下一次玻璃卡即使 live 预测带 tip 列表，MUST NOT 渲染「可能漏记」行；漏记 tip 展示仅限竖屏智能预测卡。

#### Scenario: 玻璃卡无漏记行

- **WHEN** 喂养页展示下一次预测玻璃卡，且该预测 tip 列表非空
- **THEN** 玻璃卡 MUST NOT 出现「可能漏记」文案

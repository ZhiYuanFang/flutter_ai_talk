## Why

时刻态下「此刻把握不足」与「预计{名}时刻」各占一行，垂直空间浪费且语义本是同一标题语境。产品约定：**仅时刻态**将二者合并为一行，中间以「 · 」分隔。

## What Changes

- 热态非预约卡：当 `todConfidenceLow` 且展示为**预估时刻态**（逾期或剩余 &gt;6h）时，倒计时区块标题行 MUST 显示为「此刻把握不足 · 预计{名}时刻」，不再把软标单独成行。
- **倒计时态**（未逾期且剩余 ≤6h）仍保持软标独占一行、其下为「距离下次{名}倒计时」——不合并。
- 用量 expect「预计约…」若出现，仍可单独成行；与合并后的标题行并存。
- 无软标时标题行文案不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：时刻态下钟点软标与「预计…时刻」标题同行并以「 · 」连接；倒计时态布局不变。

## Impact

- UI：`smart_prediction_screen.dart` 内 `_buildAppointmentAwareCountdown`（及软标 / caption 组装）。
- 预测算法、小组件、missAnchor 跳过逻辑不变。
- 不新建 `**/test/**`；手工验收。

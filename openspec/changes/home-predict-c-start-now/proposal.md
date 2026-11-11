## Why

喂养页最近预测玻璃卡在 C 态（逾期「补记」）打开创建 sheet 时，开始时间被预填为预测 `nextAt`。补记场景下用户更常以当下为锚点再回拨，预填过去预测时刻反而增加摩擦。

## What Changes

- C 态 CTA 仍**强制**打开统一创建记录 sheet（`time` 事件亦不得直开计时）。
- C 态 sheet 开始时间控件初值改为约等于**当下**（与 A/B 开 sheet 时一致），**不再**预填 `nextAt`。
- A/B 行为不变；卡身文案、三态窗、CTA 文案不变。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-next-predict-glass-card`：修正「Glass card CTA … C-only predicted start」——C 仍强制 sheet，但开始时刻初值改为当下，不再初始化为 `nextAt`。

## Impact

- 代码：`app/lib/ui/home_screen.dart`（`_onNextPredictGlassCta` 的 `initialStartTime`）；注释与相关说明对齐。
- 规格：基线 `openspec/specs/v2.2.1.md` 中 `home-next-predict-glass-card` 对应 Requirement / Scenario 需 delta 覆盖。
- 无 API / 后端 / 原生变更。

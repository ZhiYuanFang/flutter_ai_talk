## Why

预测落库飞入曾表现为「无动画」：排查时误以为 `SmartPredictionScreen` 未接线，实际宿主已在 `ucg_home_shell._KeepAlivePredictionPage`。随后在预测页内再挂 Overlay，与壳层叠成**双飞**。本变更去掉重复层，并加固壳层锚点/`disableAnimations` 清理。

## What Changes

- 移除 `SmartPredictionScreen` 内 `_PredictionHistoryFlyHost`；预测飞入**仅**由壳层 KeepAlive 承接。
- 壳层：`keyFor(rootEventId)`；关闭系统动画时 clear session。
- 不改喂养飞入、不改 WS 触发编排。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `history-fly-visible-landing`：预测飞入宿主 MUST 唯一（壳层 KeepAlive），MUST NOT 与页内再挂一层 Overlay。

## Impact

- 代码：`smart_prediction_screen.dart`、`ucg_home_shell.dart`。
- 无原生 / 无新依赖。

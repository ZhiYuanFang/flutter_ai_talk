## Why

网格布局下三日折线信息密度高、可读性弱；家长更需要一眼看到「距下次还有多久」。将网格主区改为时:分:秒倒计时，未超时去掉冗余短文案，超时则停表并保留「超时 …」提示。

## What Changes

- **网格**：事件卡主区由折线图改为指向 `nextAt` 的 **`HH:MM:SS`（可涨小时）倒计时**；未超时 **不得** 再展示「x 小时后」类上方短文案。
- **超时（方案 B）**：倒计时 **停在 `00:00:00`**，并展示既有风格的「超时 x 分钟 / 小时 / 天」短文案。
- **列表**：仍为近 7 日折线 + 既有相对时间；推演开关、tip、跑马灯、小组件行为不变。
- **BREAKING（仅网格呈现）**：网格不再展示折线 / 三日 X 轴；原「网格短相对时间始终展示」改为「仅超时展示」。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：网格主区倒计时与超时停表文案；废止网格常驻短相对时间与网格折线呈现要求（列表规则保留）。

## Impact

- UI：`smart_prediction_screen.dart`（`compact` 卡片分支）；可复用 `predictionClockProvider`、`formatPredictionGridRelative`（仅 overdue）。
- 不改预测算法、range 历史、服务端 API；不自动新建测试文件。
- 基线 `openspec/specs/v2.1.0.md` 尚无已合并 `smart-prediction-page`；增量叠在未归档智能预测相关 change（尤其 `prediction-layout-list-grid`）之上。

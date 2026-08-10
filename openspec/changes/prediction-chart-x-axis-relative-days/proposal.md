## Why

智能预测页折线 X 轴目前一律显示 `M/d` 日期，近端「前天 / 昨天 / 今天」不易一眼读懂。网格本应按相对日标刻度却未落地；列表近 7 日需要保留较远四天的日期，近端三天改用相对日。

## What Changes

- 折线底部 X 轴刻度文案规则统一为：相对今天差 **0 / 1 / 2** 自然日时分别显示「今天 / 昨天 / 前天」；更早之日仍显示 `M/d`。
- **网格**（近 3 日窗）：三个刻度均为「前天｜昨天｜今天」。
- **列表**（近 7 日窗）：前 4 天（今天−6 … 今天−3）仍为 `M/d`，后 3 天为「前天｜昨天｜今天」。
- 不改变取点窗口、Y 轴显隐、相对时间文案、推演开关等既有行为。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：明确列表/网格折线 X 轴日标签的相对日与日期混排规则（对齐并细化既有「网格三日」表述）。

## Impact

- UI：`app/lib/ui/smart_prediction_screen.dart` 中折线 `bottomTitles.getTitlesWidget`（及必要时极小的标签辅助函数）。
- 不改服务端 API、range 历史深度、小组件；不自动新建测试文件。
- 对照基线：`openspec/specs/v2.1.0.md` 尚无已合并的 `smart-prediction-page`；本变更增量叠在未归档的智能预测相关 change（尤其 `prediction-layout-list-grid`）之上。

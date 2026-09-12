## Why

「补充上一次」与普通新增共用 `handleEventGridTap`，非量事件直接记 `now`，无法表达「过去某次」；量事件 Sheet 仅锚当天时分。同时新增 / 编辑分属两套主 Sheet，标题无操作类型，时间区带「开始/结束」标签且并排两格，与期望的居中「今日·16:24」交互不一致。需要在同一变更内统一主业务 Sheet、补齐补充语义，并换新时间展示。

## What Changes

- **补充路径**：预测卡无 `lastAt` 时，「补充上一次」与点卡一致，打开统一 Sheet，**必须**可选跨日过去时刻；计时类开始必填、结束可选（未设显示「进行中」）；点「进行中」可设结束（默认今日·当下）。本期 **不做**「清除结束」。
- **普通新增非量**：喂养格 / 预测有 `lastAt` 等路径的 `time`/`one` **仍不**开 Sheet，直接 `now`（计时 `end=0`）。
- **预测直点叶子「确认添加」**：**保留**（仅普通新增非量）；补充路径 **不**再套该确认框（Sheet 即确认）。
- **量事件新增**：改走统一 Sheet，时间支持跨日；初值今日·当下。
- **编辑**：并入同一主 Sheet；标题与时间样式对齐；去掉「清除结束时间」控件（记错则删记录或改结束时刻）。
- **标题**：Sheet 内仅展示事件名；**不得**加「补充·/新增·/编辑·」前缀（操作差异靠主按钮文案区分）。
- **时间样式**：去掉时间标题；居中展示 `今日·16:24`（日小、时大）；分别点击日/时弹出既有日期/时分滚轮；计时为 `起 ~ 止` 或 `起 ~ 进行中`。
- **组件边界**：业务主 Sheet **一个**（`EventRecordSheet`）；日期 / 时分仍为两个轻量子弹窗；目录 picker、「大概多久一次」、确认 Dialog 不在本统一范围内。

## Capabilities

### New Capabilities

- `event-record-sheet`：统一事件记录主 Sheet（intent×type 字段显隐、操作类型标题、居中分段时间行、补充/新增 number/编辑入口契约）。

### Modified Capabilities

- `home-history-edit-sheet`：时间展示从「标签 + 并排日期/时分格」改为居中分段文案；去掉清除结束；标题仅为事件名；与统一入口对齐（行为矩阵中的 edit）。
- `home-number-event-glass-sheet`：新增 number 并入统一 Sheet；时间跨日；标题仅为事件名；废「仅今天时分」约束。
- `smart-prediction-page`：改写「补充上一次 = 普通加事件 now」约定（见未归档 `prediction-catalog-complete-cards`）；无 `lastAt` 走 supplement Sheet；有 `lastAt` 时点卡非量仍「确认添加」后 now。

## Impact

- `app/lib/ui/event_add_actions.dart`：intent（`add` | `supplement`）；补充走 Sheet；预测确认框仅 add·非量。
- `app/lib/ui/smart_prediction_screen.dart`：无 lastAt 点卡/CTA 传 supplement。
- 新建或收敛：`showEventRecordSheet`；退役/薄封装 `home_number_event_sheet.dart`、`home_history_edit_sheet.dart`。
- `app/lib/ui/home_history_time_wheel.dart`：新增居中时间行原子；复用日期/时分 picker Sheet。
- 编辑专属：媒体、删、广场同步仍仅 `edit` 段展示。
- 不改 Android 原生；不新建 `**/test/**`。

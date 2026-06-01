## Why

主页历史区当前为整行 RichText 日志流（透明度叠层 + 较大行距），在固定 220px 输入区之上占用整块 `Expanded`，视觉杂乱且单条占位偏高。用户已选定**压缩行高 + 列表顶部渐变**，并以**时间轴行**（左时间、中事件、右数量/状态）提升可读性，同时保留「最新在底部」与 OpenSpec 既有层次规则。

## What Changes

- 历史列表项改为紧凑**时间轴行**组件：左侧时间、中间事件名（备注可截断）、右侧数量/计时/状态徽章。
- 单行目标高度约 **32–36px**（较现状再压缩 padding），长文案 `maxLines: 1` + `ellipsis`。
- 列表容器顶部增加**渐变遮罩**（ShaderMask 或等效），替代逐条大段 `Opacity` 糊化；仍用 `reverse: true`，最新条在底部且字号/对比略强。
- 从 `history_line_format` 抽取主页展示用字段（时间串、事件名、尾注），详情页与 `historyLineSpans` 规则不变。
- 不改变历史加载条数、WS/SSE 合并、点击进详情、今日概览面板语义。

## Capabilities

### New Capabilities

- `home-history-timeline-row`：主页历史时间轴行布局、紧凑行高与顶部渐变展示规范。

### Modified Capabilities

- `home-input-history-sse`：更新「历史区布局与排序」中关于渐隐与字号的实现描述（由逐条 Opacity 改为顶部渐变 + 行内层次，语义仍为自下而上变弱、最新在底）。

## Impact

- `app/lib/ui/home_screen.dart`（ListView `itemBuilder`、列表包裹渐变）
- 新建 `app/lib/ui/home_history_timeline_tile.dart`（或等价命名）
- `app/lib/data/history_line_format.dart`（新增 `HistoryHomeRowDisplay` 等展示模型，可选）
- OpenSpec delta：`openspec/changes/pangbao-app/specs/home-input-history-sse` 归档时合并

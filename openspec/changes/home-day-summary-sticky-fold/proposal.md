## Why

按日吸顶汇总目前用 `estimateHomeDayStickyExtent` 估高，常大于真实 chip 高度，吸顶底部出现大块空白。多事件日默认铺满全部折行也占过高。需要真高自适应，并默认只展示一行、可展开/收起。

## What Changes

- 日期吸顶 extent MUST 按该日**实测**内容高度设置（收起/展开各一份），MUST NOT 长期依赖偏大的折行估高导致底部空白。
- 按日汇总 chip **默认展示一行**（超出裁切）；当内容超过一行时 MUST 提供展开/收起；展开后展示全部折行。
- 展开/收起入口放在**日期行右侧**文案（「展开」/「收起」），MUST NOT 与 chip 打开单日详图手势冲突。
- 展开态 **按日独立** 记忆（滚动到另一日不强制继承）。
- 无 totals 时仍仅日期；chip 开图与 usage 上报行为不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-per-day-summary-sticky`：修正吸顶高度为实测自适应；新增默认一行折叠与按日展开/收起。

## Impact

- UI：`home_history_date_header.dart`、`home_day_summary_chips.dart`、`home_history_scroll.dart`（测高缓存 + 展开态）；可删除或降级纯估高路径。
- 对照：`home-per-day-summary-sticky`（本 follow-up）；旧 `HomeTodaySummaryPanel` 两行折叠改为**一行**。
- 不改日键、聚合、Sheet、usage 契约。

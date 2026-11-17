## ADDED Requirements

### Requirement: Accuracy chart pane MUST NOT long-press toggle layout

The accuracy chart pane (bars or summary) on the smart prediction vertical list MUST NOT register a long-press that toggles list↔waterfall (grid) layout. Chart short-press behaviors (day summary / return from summary) MUST remain as previously specified. Layout switching MUST remain available from the title-bar control only (for this gesture family).

准确率图区 MUST NOT 长按切布局；点柱小结等短按行为不变；布局仍仅经标题栏切换。

#### Scenario: Long-press bars does not switch layout

- **WHEN** 竖列表准确率柱图上长按且当前为列表布局
- **THEN** 客户端 MUST NOT 因该长按切换到瀑布/紧凑布局

## REMOVED Requirements

### Requirement: Accuracy chart pane SHALL long-press toggle list and waterfall layout

**Reason**: 与整卡长按一并退役，避免图区误触切回瀑布或再切列表。

**Migration**: 去掉准确率 pane 的 `onLongPressLayout`（或等价）接线。

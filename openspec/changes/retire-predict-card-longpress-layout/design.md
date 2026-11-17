## Context

基线 `v2.2.1`：`smart-prediction-page` 要求竖屏整卡长按切布局；`predict-list-accuracy-bars` 要求准确率图区显式长按同切。实现上 `onLongPressLayoutToggle` 与 AppBar 共用 `predictionCardsLayoutProvider`。产品选定 **只去长按**（档 A），保留标题栏入口与 list 准确率面。

## Goals / Non-Goals

**Goals:**

- 卡/图区长按不再改布局。
- 标题栏切换与持久化/usage 不变。

**Non-Goals:**

- 不退役 list/准确率柱；不删 AppBar 图标；不改默认 grid。

## Decisions

1. **接线删除**：`onLongPressLayoutToggle` 恒为 null（或不再传入）；卡外包 `onLongPress` 与准确率 pane 的 layout 长按一并去掉。  
2. **保留**：标题行 `Icons.view_*` 切换、`setLayout`、client-usage layout 事件。  
3. **横屏**：本就不该用该长改竖屏偏好；保持现状。

## Risks / Trade-offs

- [用户不知如何进准确率] → 仍靠标题栏图标；若发现可再加 hint（本变更不做）。

## Open Questions

- （无）范围已定为只去长按。

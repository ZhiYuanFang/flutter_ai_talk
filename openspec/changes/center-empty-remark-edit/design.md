## Context

`EventRemarkCollapsedRow` 在备注为空时用 `Row` + 末尾 `Spacer()`，把「编辑备注」顶到左侧。基线 `event-record-remark-sheet-ux` 已规定空态仅显示「编辑备注」、有备注时正文+编辑入口；本变更只补空态对齐。对照 `openspec/specs/v2.2.1.md`。

## Goals / Non-Goals

**Goals:**

- 空备注折叠行：编辑入口横向居中。
- 有备注布局与交互不变。

**Non-Goals:**

- 改展开 TextField、快捷标签、确认钮全宽。
- 新增占位文案。
- 预约 sheet / 其它备注 UI。

## Decisions

1. **只改共用组件** `event_remark_collapsed_row.dart`；create / 历史编辑自然同步。  
2. **空态**：`MainAxisAlignment.center`（或等价居中），去掉单侧尾部 `Spacer()`。  
3. **有备注**：保持 `Expanded` 正文 + 右侧编辑文案/图标。  
4. **整行仍可点** `InkWell` 展开；居中不缩小热区以外的语义。

## Risks / Trade-offs

- [居中后热区仍全宽 InkWell] → 可接受；若误触左右空白展开，与现左对齐全宽点击一致。  

## Open Questions

- （已定）仅空态居中；有备注不改。

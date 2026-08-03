## Context

`companion-select-copy` 方案 M 后：用户气泡 `SelectableText` 可选；助手为玻璃内 `MarkdownBlock(selectable: true)`（内层 `SelectionArea`），真机表现为按下高亮、松手清空、无手柄，系统选区菜单出不来。

C′a 依赖选区先能提交，再在选区上方出「复制」。

## Goals / Non-Goals

**Goals:**

- 助手完成态答案：长按松手后选区尽量保持，可出现手柄。
- 选区上方工具条提供「复制」，写入剪贴板的是**当前选中片段**。
- tip 注入进树洞的助手气泡与普通助手同路径。

**Non-Goals:**

- 常驻复制图标（旧方案 C）。
- 松手后自绘 Overlay 兜底（C′b），除非 A 验证失败再开增量。
- 改造用户气泡 toolbar（已可用系统选区）。
- 首页 tip 可选。
- thinking / 错误文案选区。

## Decisions

### 1. 方案 A：气泡级 `SelectionArea` 在玻璃外

```
SelectionArea(                    ← 选区所有者 + contextMenuBuilder
  child: UcgComposeLightGlassPanel(
    child: ClinicAnswerBody(
      selectable: false,          ← Markdown 不再套 SelectionArea
      … MarkdownBlock …
    ),
  ),
)
```

- **备选**：去掉玻璃 `ClipRRect` — 仅当外包仍无法提交时再试 `clipBehavior: Clip.none` 或透明直出。
- 流式中仍可用普通 `Text`；流式结束再走上述结构。

### 2. 方案 C′a：`contextMenuBuilder`「复制」

- 使用 `SelectionArea.contextMenuBuilder`，基于 `AdaptiveTextSelectionToolbar` / `ContextMenuButtonItem`，主按钮文案「复制」。
- `onPressed`：`Clipboard.setData(ClipboardData(text: selected))`，`selected` 来自 `EditableText.getSelectionRect` / `contextMenuBuilder` 回调的 `SelectableRegionState` 可取文本（按 Flutter API：`contextMenuBuilder: (context, selectableRegionState)` 用 `selectableRegionState` 的 copy 或读 selection）。
- 复制成功可用现有 `showAppToast('已复制')`（轻量反馈，可选）。
- 不强制隐藏系统其它按钮；至少保证「复制」可用。若平台默认已有 Copy，可保留默认 toolbar 或只保留「复制」——**决策**：优先平台默认 toolbar（已含 Copy/复制），若中文环境标签不友好再自定义仅「复制」。  
  **落点**：自定义 buttonItems，明确一项 `label: '复制'`，避免依赖英文 Copy。

### 3. 与列表的关系

- 列表级仍**不**包 `SelectionArea`（方案 M 结论不变）。
- 每条助手气泡各自一个 `SelectionArea`。

### 4. 玻璃裁剪

- 先只做「SelectionArea 在外」；若手柄仍被裁，再对助手这条路径的 `ClipRRect` 设 `clipBehavior: Clip.none` 或把 padding 加大，避免改全局玻璃组件行为（优先局部包一层，不改 `UcgComposeLightGlassPanel` 默认，除非必要）。

## Risks / Trade-offs

- [A 后仍松手清空] → 记录真机结果；另开 C′b，不在本 change 硬撑。  
- [Markdown WidgetSpan 段不可选] → 正文段落优先；整段可用多次选择。  
- [BackdropFilter 仍干扰] → 局部弱化裁剪或透明底试验。  
- [contextMenuBuilder API 随 Flutter 版本差异] → 对照当前 SDK，用官方 Adaptive toolbar 模式。

## Migration Plan

1. 助手气泡外包 `SelectionArea`，`ClinicAnswerBody(selectable: false)`。  
2. 接上 `contextMenuBuilder`「复制」。  
3. 真机：松手后选区/手柄、「复制」写入剪贴板。  
4. 回归：用户气泡、首页 tip。

可整 diff 回滚。

## Open Questions

- （无阻塞）用户侧是否统一自定义「复制」文案 — 本 change 不做。

## Why

树洞用户气泡在方案 M 下已可稳定选区复制，但助手（系统）气泡仍停留在「按下有高亮、松手消失、无手柄」，无法用系统选区菜单复制。需要先让助手选区能够提交，并在选区上方提供「复制」操作（方案 C′a）。

## What Changes

- 助手气泡：将选区所有者移到玻璃面板外（方案 A），内层 Markdown 不再自套 `SelectionArea`，使长按松手后选区可保持并出现手柄（尽力而为）。
- 助手气泡：通过 `SelectionArea.contextMenuBuilder`（或等价选区 toolbar）在选区上方展示「复制」，复制**当前选中片段**到剪贴板（方案 C′a）。
- 不采用常驻「复制」图标；用户气泡保持现有 `SelectableText` 行为（可用系统菜单；本变更不强制改用户侧 toolbar）。
- 首页 tip 仍 `selectable: false`，不改 tip 手势。
- 若仅靠 A 仍无法在真机提交选区，实现阶段可记录并回退评估 C′b（松手 Overlay），但不在本提案默认范围内。

## Capabilities

### New Capabilities

- `companion-assistant-selection-copy`：树洞助手气泡选区提交与选区上方「复制」。

### Modified Capabilities

- （无）不修改 tip-bridge / clinic 契约；与进行中的 `companion-select-copy`（用户侧选区）互补。

## Impact

- 代码：`pangbao_ai_screen.dart`（助手气泡壳）、`clinic_answer_body.dart`（树洞路径 `selectable: false`）、可能小幅涉及玻璃裁剪（`clipBehavior` / 结构）。
- 依赖：Flutter `SelectionArea` / `AdaptiveTextSelectionToolbar`（或 `contextMenuBuilder`）、`Clipboard`。
- 不改原生、不改后端、不新增 Debug tag。

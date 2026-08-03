## Why

树洞（陪伴）对话中，用户需要把助手答复或自己的提问复制到别处（备忘、搜索、转发）。当前用户气泡与流式中正文用普通 `Text`，选区不可靠；已完成 Markdown 虽默认 `selectable: true`，在 `ListView` 内长按选中体验仍偏弱。需要明确「可选择复制」的用户可见行为。

## What Changes

- 树洞消息列表：已完成的助手答案（含 tip 注入气泡）支持系统长按选区与复制。
- 用户气泡正文支持选区与复制；同意后以「填入输入框」图标保留填入（不用单击气泡，避免清选区）。
- 助手答案流式进行中可不强制可选；流式结束后必须可选。
- 消息列表不包外层 `SelectionArea`（按气泡各自选区）。
- thinking 折叠区、错误文案：本变更不要求可选（可后续增量）。
- 首页 tip 面板保持 `selectable: false`（手势冲突），本变更不改 tip 手势。
- 不新增一键「复制」工具栏按钮（首版靠系统选区菜单即可；若仍不稳再加）。

## Capabilities

### New Capabilities

- `companion-text-selection`：树洞聊天列表文本选择与复制行为。

### Modified Capabilities

- （无）不修改 tip-bridge / clinic WS 契约；仅 UI 选区行为。

## Impact

- 代码：`pangbao_ai_screen.dart`（`_buildItem` / 列表壳）、`clinic_answer_body.dart`（若需统一 `SelectionArea` 或流式路径）。
- 依赖：Flutter 文本选择 / `SelectionArea` / `SelectableText` / `markdown_widget` 的 `selectable`。
- 不改 Android/iOS 原生、不改后端 API、不新增 Debug tag。

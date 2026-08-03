## Context

树洞消息列表在 `pangbao_ai_screen.dart`：`ListView.builder` + `_buildItem`。

- 助手已完成答案：`ClinicAnswerBody`（`selectable` 默认 `true` → `MarkdownWidget`）。
- 助手流式中：`ClinicAnswerBody` 走普通 `Text`，不可选。
- 用户气泡：普通 `Text`，外层 `GestureDetector.onTap` 填回输入框。
- 首页 tip：`selectable: false`，本变更不动。

用户反馈「不能选择复制」时，常见路径是用户气泡或流式中正文；ListView 内 Markdown 选区有时也不稳。

## Goals / Non-Goals

**Goals:**

- 已完成助手答案（含 tip 注入）长按可选、系统菜单可复制。
- 用户气泡正文可选可复制；同意后单击填输入仍可用。
- 流式结束后助手答案可选（流式中不强制）。

**Non-Goals:**

- thinking / 错误文案选区。
- 气泡旁「复制」图标或自定义上下文菜单。
- 首页 tip 面板选区。
- 跨气泡一次选中多条消息（nice-to-have，不强制）。

## Decisions

### 1. 列表不包 `SelectionArea`（方案 M）

- **去掉**消息列表外层 `SelectionArea`：与 `ListView` 在松手时抢手势会导致「长按有高亮、一放就消失」。
- 每条气泡各自拥有选区，不追求跨气泡一次选中。

### 2. 助手答案：`MarkdownBlock` + `selectable: true`

- 树洞使用默认 `selectable: true`；`scrollable: false` 走 `MarkdownBlock`（自带一层 `SelectionArea`，无内层 `ListView`）。
- 流式阶段普通 `Text`，不强制可选；结束后 Markdown 可选。
- 首页 tip 仍 `selectable: false`。

### 3. 用户气泡：`SelectableText` + 图标填入

- 正文 `SelectableText`；**不**用 `GestureDetector` 包住正文。
- 已同意时左侧小图标「填入输入框」替代原单击填入。

### 4. 明确排除

| 区域 | 本变更 |
|------|--------|
| `_ThinkingBlock` | 不改 |
| 错误 `Text` | 不改 |
| `HomeTipPanel` / tip `selectable: false` | 不改 |
| 「非医疗建议」脚注 | 不要求可选 |

## Risks / Trade-offs

- [助手 Markdown 选区与列表滚动] → 用 `MarkdownBlock` 减轻；若仍松手消失再加整段复制兜底。  
- [填入改为图标] → 发现成本略升，换选区稳定。  
- [流式中不可选] → 产品接受；结束后立刻可选。

## Migration Plan

1. 去掉列表 `SelectionArea`。  
2. 用户 `SelectableText` + 填入图标。  
3. 助手 `MarkdownBlock(selectable: true)`。  
4. 手工：长按松手后选区仍在；可拖动手柄；首页 tip 不可选。

无数据迁移、无服务端、可整 diff 回滚。

## Open Questions

- （无阻塞）是否后续给错误文案也加可选——另开增量。

## Context

- **现状**：`PangbaoAiScreen._ThinkingBlock` 折叠时 `ConstrainedBox(maxHeight: 5×lineHeight)` + `SingleChildScrollView` + `_scrollToLatest()`；`overflow` 用 `\n` 计数；`thinkingInnerPinned` 控制「跟随最新」chip。
- **问题**：流式 thinking 时常停在最旧内容；用户未见「跟随最新」，说明内层 `jumpTo` 未可靠执行，而非 pin 拦截。
- **决策**：折叠态改为 **尾部对齐裁剪窗口**（bottom-aligned clip），不依赖内层滚动跟随；展开态仍展示全文并可滚动。

## Goals / Non-Goals

**Goals:**

- 折叠态固定高度窗口内 **始终展示 thinking 尾部**（最新流式内容可见）。
- 流式 `thinking_delta` 更新时无需 `ScrollController.jumpTo`。
- 溢出提示（「点击展开」、顶部渐变）在 **视觉溢出** 时显示，而非仅 `\n` 行数。
- 展开态展示完整 thinking，用户可滚动查看历史。

**Non-Goals:**

- 折叠态内查看 earlier thinking（必须展开）。
- 修改 WS 协议、answer Markdown、外层 ListView 跟随逻辑。
- 展开态复杂的 pin/跟随最新（v1 可仅用普通内滚，无 chip）。
- 新增自动化测试文件。

## Decisions

### 1. 折叠态：底部对齐 + 裁剪（Tail Window）

**Decision**：折叠时使用固定高度 `SizedBox` + `ClipRect` + `Align(alignment: Alignment.bottomLeft)` 包裹完整 `Text(thinking)`，让视口自然露出文本 **底部** 区域。

```
┌─ ClipRect (h = 5 × lineHeight) ─┐
│                                 │
│     （上方被裁掉）               │
│  ...较早内容不可见...            │
│  第 N-1 行                      │
│  第 N 行（最新）▍               │  ← Align bottom
└─────────────────────────────────┘
```

**Why**：零滚动状态机；流式 append 后 layout 自动露出末尾；避免 `maxScrollExtent` 竞态。

**Alternatives**：保留 `SingleChildScrollView` + 双帧 `jumpTo` — 仍脆弱；`TextPainter` 截断字符串 — 需处理 UTF-16/换行边界，维护成本高。

### 2. 展开态：保留 `SingleChildScrollView`（可选初始滚底一次）

**Decision**：`thinkingExpanded == true` 时用 `SingleChildScrollView` 展示全文；进入展开时可 `jumpTo(max)` 一次，**不做**流式 pin/chip。

**Why**：展开用户意图是读全文；折叠已解决「跟最新」主路径。

### 3. 移除折叠态 pin 状态机

**Decision**：删除 `_ChatItem.thinkingInnerPinned`、`onInnerPinChanged`、折叠态「跟随最新」`ActionChip`、`_onInnerScroll` pin 逻辑及折叠态 `ScrollController`。

**Why**：尾部窗口不需要跟随；简化状态与 `setState` 回调。

### 4. 溢出检测改用布局测量

**Decision**：用与展示相同的 `TextStyle` + `TextPainter`（或 `LayoutBuilder` 宽度）测量全文高度，与折叠窗口高度比较判定 `hasVisualOverflow`；用于控制顶部渐变与「点击展开」。

**Why**：修复「单段长文无 `\n` 但不显示溢出提示」的问题。

### 5. 流式光标

**Decision**：折叠与展开均在流式阶段于文本末尾追加 `▍` 光标（保持现状），尾部窗口下光标始终可见。

## Risks / Trade-offs

- **[Risk] 极窄屏下 `Align.bottom` 裁切一字行** → 使用与现有一致的 `lineHeight` 18 与 `fontSize` 12；实现期 Web/手机各验一条长段落。
- **[Risk] 折叠态无法预览 earlier 内容** → 产品已接受；「点击展开」文案保留。
- **[Risk] 顶部渐变在 tail 模式下语义变化** → 渐变仍表示「上方还有隐藏内容」，与裁切方向一致。

## Migration Plan

- 纯客户端 UI 变更；发版即生效。
- 回滚：恢复 `SingleChildScrollView` + `_scrollToLatest` 实现即可。

## Open Questions

- 实现期是否将 `_ThinkingBlock` 抽到 `app/lib/ui/widgets/clinic_thinking_block.dart`（可选，tasks 中二选一）。

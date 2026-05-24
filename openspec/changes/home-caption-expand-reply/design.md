## Context

- `HomeInputCaption`：280×52、`maxLines: 3`、`TextOverflow.ellipsis`，展示 `_homeInputCaptionText()`（回复 > 转写 > 聆听中）。
- 底部 220px `Stack` 中 `Positioned.fill` 的 `Listener` 用于按住说话，当前叠在输入列之上，可能阻挡字幕点击。
- 用户确认：**仅 `_chatReply`** 可展开；交互形式为 **BottomSheet**。

## Goals / Non-Goals

**Goals:**

- 服务端回复在字幕框被截断时可点，BottomSheet 显示全文。
- 未截断、转写、聆听中：无展开入口，行为与现网一致。
- 语音按住 / 滑出取消不受影响。

**Non-Goals:**

- 转写 partial 展开、历史列表 remark 展开、原地增高字幕框、跳转新页面。

## Decisions

### 1. 可展开判定

`HomeInputCaption` 增加 `expandable: bool`（由 `HomeScreen` 在 `reply == _chatReply` 时传入）。

截断检测：`LayoutBuilder` + `TextPainter`（同 `maxLines: 3`、同 `TextStyle`、宽度 280）→ `didExceedMaxLines`。

仅当 `expandable && didExceedMaxLines` 时：
- 包裹 `InkWell` / `GestureDetector`
- 可选副文案「点击查看全文」或右侧 `Icons.unfold_more`（10sp）

### 2. BottomSheet 内容

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + viewPadding.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('服务端回复', style: titleSmall),
        Flexible(child: SingleChildScrollView(
          child: SelectableText(fullReply),
        )),
      ],
    ),
  ),
);
```

由 `HomeScreen` 提供 `void showReplySheet(String text)`，`HomeInputCaption` 回调 `onTapExpand`。

### 3. 手势与层序

将 **字幕** 从 `_buildVoiceOrb` / `_buildTextInput` 的 `Column` 中抽出，在底部 `Stack` 单独一层：

```
Stack:
  Align(center) → 仅语音球 / 文字输入（无字幕）
  Positioned(top: ~8, center) → HomeInputCaption（在 Listener 之上）
  Positioned.fill → Listener（按住）
  响度柱 / 诊断 / 切换
```

字幕层 `Material` + `InkWell`，仅占用 52px 高区域，不挡语音圆（圆在下方 Align 中心）。Listener 仍全屏接收圆盘手势；字幕区域点击由上层消费。

**备选（不采用）**：缩小 Listener 仅罩圆 — 移出取消手势复杂。

### 4. HomeScreen 接线

```dart
HomeInputCaption(
  text: _homeInputCaptionText(),
  expandable: _chatReply != null && _chatReply!.trim().isNotEmpty
      && _homeInputCaptionText() == _chatReply!.trim(),
  onExpand: () => _showReplyBottomSheet(context, _chatReply!),
)
```

语音/文字模式共用同一字幕 `Positioned`（避免重复逻辑）。

### 5. 聆听中 / 转写

`expandable: false`；`_partial` 显示时即使很长也不提供 BottomSheet（符合「只展开服务端回复」）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 字幕与圆盘垂直间距变紧 | `Positioned(top: 4)` 微调 |
| TextPainter 与 Text 样式不一致导致误判 | 共用同一 `TextStyle` 工厂方法 |
| BottomSheet 遮挡输入区 | `isScrollControlled` + 合理 maxHeight |

## Migration Plan

- 纯客户端 UI；无数据迁移。

## Open Questions

- （无）已确认：仅服务端回复、BottomSheet。

## Context

- 主页 `body`：`Expanded(历史)` 内嵌 `Column`：`Expanded(历史 ListView)` + 条件 `HomeVoicePartialStrip` + `Divider` + 底栏 `SizedBox(220)` 为 `Column(可选 HomeInputCaption + Expanded(Stack 语音球))`。
- `_showPartialStrip`：语音模式且 `_partial` 非空且无 `_chatReply`。
- `_homeInputCaptionText()`：回复优先；语音聆听中固定返回「聆听中…」，导致底栏字幕槽占用约 52px、语音球被挤下。
- `home-caption-expand-reply`：底栏 `HomeInputCaption` 对 `_chatReply` 截断时可点击 `showHomeReplyBottomSheet`。

## Goals / Non-Goals

**Goals:**

- 语音模式下，partial 与服务端回复均在**历史上方同一条消息条**展示，优先级：reply > partial。
- 语音底栏 220px **仅**语音球、按住 Listener、响度柱、录音诊断等；球垂直位置全程不变。
- 取消「聆听中…」占位；连接/开录无文案时 strip 隐藏。
- 语音模式长回复：在消息条上复用 BottomSheet 展开（截断检测逻辑可抽共用）。
- 将 `HomeVoicePartialStrip` 泛化为 `HomeVoiceMessageStrip`（或重命名文件），减少重复组件。

**Non-Goals:**

- 改变 ASR/WebSocket、`sendCommand`、`_applyChatReply` 清空 `_partial` 的时序。
- 文字输入模式的底栏字幕与展开行为（保持现状）。
- 连接阶段在球上新增 loading 动画（除非实现时发现必要，可后续小改）。

## Decisions

### 1. 文案数据源与显示条件

```dart
String? get _voiceStripText {
  if (_inputChannel != voice) return null;
  final reply = _chatReply?.trim();
  if (reply != null && reply.isNotEmpty) return reply;
  final partial = _partial.trim();
  if (partial.isNotEmpty) return partial;
  return null;
}

bool get _showVoiceMessageStrip => _voiceStripText != null;
```

- **不得**在 `_voiceStripText` 分支中返回「聆听中…」。
- `_applyChatReply` 仍清空 `_partial`；strip 从 partial 切到 reply 由状态自然完成。

### 2. 底栏结构（语音模式）

```dart
SizedBox(
  height: 220,
  child: Stack(  // 全高，无 Column 顶栏字幕
    children: [
      Align(center, child: voiceOrb),
      Positioned.fill(child: voiceListener),
      // level bars, diagnostics, mode switch
    ],
  ),
)
```

`_buildHomeInputCaption` 仅在**文字模式**且 `_homeInputCaptionText()` 非空时插入底栏（文案仅 `_chatReply`，不含聆听中）。

### 3. HomeVoiceMessageStrip

- 自 `HomeVoicePartialStrip` 演进：保留 `AnimatedSize`、`maxHeight = 30% 屏高`、`SingleChildScrollView`、partial 更新时滚到底部。
- 新增可选参数：
  - `expandable: bool`（仅 reply 且文本在 strip 内被截断时为 true，可用 `TextPainter` 与 max 高度比对，或简化为 reply 且字符数/行数超阈值）
  - `onExpand: VoidCallback?` → `showHomeReplyBottomSheet`
- partial 模式：`expandable == false`，不注册 `InkWell`。
- reply 与 partial 切换：可选 `ValueKey`（`reply` vs `partial`）或 `AnimatedSwitcher` 减轻闪动。

### 4. 展开与手势

- 语音模式底栏无字幕 → 不存在「字幕点击 vs 按住 Listener」冲突；展开仅发生在 strip 的 `GestureDetector`/`InkWell` 上。
- strip 位于历史下方，不在 220px 手势区内，不影响按住说话。

### 5. 文件与命名

- 推荐：`home_voice_message_strip.dart`，类名 `HomeVoiceMessageStrip`；`home_voice_partial_strip.dart` 可删除或 export 别名过渡。
- `home_screen.dart`：替换 `_showPartialStrip`、`_homeInputCaptionText` 分支、底栏 `Column` 构建。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 连接阶段无任何文案，用户不知是否在录 | 接受；依赖响度柱/球态；后续可加球上 indicator |
| partial→reply 切换视觉跳变 | `AnimatedSwitcher` 200ms |
| reply 在 strip 内截断检测比底栏 3 行复杂 | 首版可对 reply 一律可点展开，或复用与 `HomeInputCaption` 相同的 maxLines 估算 |
| 文字模式误删底栏回复 | `_inputChannel` 分支显式分离 |

## Migration Plan

1. 实现 `_voiceStripText` / `_showVoiceMessageStrip` 与 strip 组件。
2. 语音底栏改为纯 `Stack`；移除语音路径 `HomeInputCaption`。
3. 删除 `_homeInputCaptionText` 中「聆听中…」分支。
4. 手动验证：按住无 strip → partial 出现 → 松手保留 → reply 在 strip → 点击展开 → 再按住清空 reply。

## Open Questions

- reply 截断检测：与底栏 3 行一致，还是 strip 多行下「超出 maxHeight 才可展开」？**建议**：reply 在 strip 内若 `scrollController.hasClients && maxScrollExtent > 0` 则 `expandable`。

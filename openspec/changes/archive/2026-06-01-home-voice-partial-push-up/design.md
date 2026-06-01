## Context

- 主页 `body`：`Expanded(历史 reverse ListView)` + `Divider` + 底栏 `Column`（顶栏字幕 52px + 球区 `Expanded`）。
- `_homeInputCaptionText()`：回复 > partial >「聆听中…」；底栏字幕固定 `maxLines: 3`。
- 已实现：`home-caption-expand-reply`（仅 `_chatReply` BottomSheet）、字幕不压球（底栏上分区）。

## Goals / Non-Goals

**Goals:**

- 方案 A：转写条位于历史与 `Divider` 之间，挤压 `Expanded(历史)`。
- `_listening` 且 `_partial` 非空时全文优先展示（受 maxHeight 约束）。
- 底栏 220px 语音球区域高度稳定；转写不在球上方叠层。

**Non-Goals:**

- 改变 WS/ASR 协议、历史排序/渐隐、`sendCommand` 语义。
- 服务端长回复改用顶栏（仍用底栏预览 + BottomSheet）。
- 文字输入模式实时转写（无 partial）。

## Decisions

### 1. 布局结构

```dart
Column(
  children: [
    banner, todaySummary,
    Expanded(
      child: Column(
        children: [
          Expanded(child: historyList),      // 被挤矮
          if (_showPartialStrip)              // 见下
            HomeVoicePartialStrip(text: _partial),
        ],
      ),
    ),
    Divider,
    SizedBox(height: 220, child: bottomInputOnly), // 无 partial 字幕
  ],
)
```

`_showPartialStrip`：

```text
_voiceHoldActive 或 _listening 后的「等待回复」窗口：
  (_partial.isNotEmpty) && (_chatReply == null || _listening)
```

简化实现：

- **显示**：`_partial.isNotEmpty && _chatReply == null`（有转写且尚未被回复覆盖）
- **隐藏**：`_chatReply` 非空；新一轮按住开始时清空回复后显示新 partial

「聆听中…」无 partial：不显示 strip。

### 2. HomeVoicePartialStrip

- `Padding` + `Material`（`surfaceContainerLow`）+ `SelectableText` 或 `Text`，`textAlign: start/center`。
- `maxLines: null` 在布局约束内；外层 `ConstrainedBox(maxHeight: screenH * 0.30)`。
- 超出 maxHeight：`SingleChildScrollView` 包 Text，默认滚到底部（最新字可见）。
- `AnimatedSize`（~200ms）高度变化，减少历史区跳动生硬感。
- partial 更新频繁：文本直接 setState，高度由布局计算（避免每字 Animation）。

### 3. 底栏字幕槽分工

`_buildHomeInputCaption` / `_homeInputCaptionText()`：

- 当 `_partial.isNotEmpty && _chatReply == null`：**底栏不显示 partial**（避免重复）；strip 独占转写。
- 当 `_chatReply` 非空：底栏显示回复（可展开 BottomSheet）。
- 当仅「聆听中…」：底栏可选单行「聆听中…」或 strip 不显示时底栏显示——采用 **strip 不显示时底栏显示「聆听中…」**。

```dart
String? _homeInputCaptionText() {
  if (_chatReply?.trim().isNotEmpty == true) return _chatReply;
  if (_partial.isNotEmpty) return null; // 由 strip 展示
  if (_listening && voice) return '聆听中…';
  return null;
}
```

### 4. 与回复展开共存

- `_chatReply` 到达：`setState` 隐藏 strip、底栏显示回复；`expandable` 逻辑不变。

### 5. 语音模式限定

- strip 仅 `_inputChannel == voice` 时参与布局；文字模式不插入。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 极长 partial 占满 30% 屏 | ScrollView + maxHeight |
| 历史几乎不可见 | maxHeight 30%；松开结束 strip 可保留但更短 |
| ListView reverse 与 strip 视觉间隙 | strip 与 ListView 间 4px padding |

## Migration Plan

- 纯 UI；无后端与 prefs。

## Open Questions

- （无）用户确认方案 A。

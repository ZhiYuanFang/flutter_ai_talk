## Context

- 主页底部 `SizedBox(height: 220)` 内：`home_screen.dart` 的 `_buildVoiceOrb` 将 `_partial` 放在球上方、`_chatReply` 放在球下方，均为 `Column` 子节点，总高度随回复增长，在固定容器内**垂直挤压**，导致转写被裁切或不可见。
- 云端/Vosk/系统 STT 均已向 `_partial` 回调写值；问题本质是**布局与状态生命周期**（松手即 `_partial = ''`），而非识别链路缺失。
- 用户选定**方案 B**：固定高度字幕区 + **覆盖**展示（非上下叠两行）。

## Goals / Non-Goals

**Goals:**

- 语音与文字主输入共用一块**固定高度**字幕区（约 48–56 logical px，最多 3 行，`ellipsis`）。
- 展示优先级：`服务端回复` > `转写预览`；同一时刻仅一种主文案。
- 松手后**保留**转写直至回复到达并覆盖；新一轮按住时清空字幕区并重新累积转写。
- 抽取可复用组件（如 `HomeInputCaption`），`home_screen` 只负责状态。

**Non-Goals:**

- 不调整历史区、今日汇总、识别引擎、语音 WS 协议。
- 不做多段对话气泡、不保留转写与回复并排对照。
- 不改变 `sendCommand` 与历史 WS 行为。

## Decisions

### 1. 布局：方案 B（固定字幕槽 + 球/输入在下）

```
┌─────────────────────────────┐  ← 220px 输入区
│  ┌─────────────────────┐   │
│  │ 字幕框 (固定高度)    │   │  ← 始终占位（可空）
│  └─────────────────────┘   │
│         ( 语音球 )          │
│    [趋势]          [切换]   │
└─────────────────────────────┘
```

- **理由**：高度可预测，回复不再把转写顶出视口。
- **备选 A**（动态高度 Column）：已否决，仍会挤占。

### 2. 文案来源：单一 `displayCaption` 推导

| 阶段 | `displayCaption` |
|------|------------------|
| 按住且 `_partial` 非空 | `_partial` |
| 按住且 `_partial` 为空 | 可选短提示「聆听中…」（同一样式，非第二行） |
| 松手后至回复前 | 保留最后一帧 `_partial`（不在 `_onVoiceEnd` 清空） |
| 回复到达 | `_chatReply` 覆盖（`_partial` 可置空或忽略） |
| 新一轮按住 | 清空 `_chatReply` 与 `_partial`，再写转写 |

实现：`final caption = (_chatReply?.trim().isNotEmpty == true) ? _chatReply! : (_partial.isNotEmpty ? _partial : listeningHint);`

### 3. 覆盖语义

- 使用**一个** `Text`（或 `AnimatedSwitcher` 可选）在固定 `SizedBox` 内居中；**不得**在字幕区外再渲染 `_chatReply`。
- 文字模式：移除输入框下方的回复 `Text`，改为同一 `HomeInputCaption` 置于输入框**上方**（与语音模式对齐：字幕在上、控件在下）。

### 4. 状态调整（`home_screen.dart`）

- `_onVoiceEnd`：删除松手时对 `_partial = ''` 的立即清空；仍以 `fromEngine` 非空优先作为发送文本，发送逻辑不变。
- `_onVoiceCancel`：清空 `_partial` 与进行中的展示。
- `onPointerDown`：`setState` 清空 `_chatReply`、`_partial`，再 `startSession`。
- `_onTextSubmit` / `_onVoiceEnd` 收到 `reply` 后：`setState(() => _chatReply = reply)`，可选清空 `_partial` 避免优先级歧义。

### 5. 组件边界

- 新建 `lib/ui/home_input_caption.dart`：`HomeInputCaption({required String? text, bool showListeningHint})`，固定宽高与主题 `bodySmall`/`labelMedium`。
- 语音球内移除独立 `_partial` / `_chatReply` 子树；文字区移除底部回复块。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 长回复 3 行截断 | `maxLines: 3` + `ellipsis`；与现 `bodySmall` 一致 |
| 松手后长时间无回复仍显示旧 partial | 可后续加「处理中…」；本变更不强制 |
| 220px 区更挤 | 字幕固定 ~52px，球略上移；必要时略减球 padding |
| 文字模式字幕在输入上方 | 与语音一致，用户已要求「一起改」 |

## Migration Plan

- 纯客户端 UI/状态变更，无数据迁移；发版后即生效。
- 回滚：恢复 `Column` 双 `Text` 与松手清空 `_partial`。

## Open Questions

- 无。聆听中占位文案是否显示可在实现时采用「仅云端/仅 `_listening`」细调，不阻塞归档。

## Context

- `home_screen.dart`：`Listener` 包住语音圆，`onPointerDown` → 准备/录音，`onPointerUp` → 一律 `_onVoiceEnd`，`onPointerCancel` → `_onVoiceCancel`。
- 无 `onPointerMove`；圆外松手仍会发送。
- 已有 `_voiceHoldActive` / `_voiceHoldSeq` 处理异步连接期间松手。

## Goals / Non-Goals

**Goals:**

- 取消区 = **语音圆**（直径 132，圆心由 `GlobalKey` + `RenderBox` 计算；可加 ~8px 容差）。
- `_slideToCancel`：`true` 当指针在圆外且仍处于按住流程。
- **滑回圆内**：`_slideToCancel = false`，文案恢复「松开结束」，松手可发送。
- 松手分流：` _slideToCancel || _voiceSlideCanceledLatch` → `_onVoiceCancel()`；否则 `_onVoiceEnd()`。
- 取消态清空 `_partial`，不 `sendCommand`。

**Non-Goals:**

- 不做微信式固定上滑取消条（仅几何圆外）。
- 不改识别引擎协议、字幕框布局、趋势 AppBar。

## Decisions

### 1. 命中与跟踪

```
底部 220px Stack
  └─ Listener (behavior: translucent, 整块底部或至少包住圆+余量)
        onPointerMove → 更新 _slideToCancel
        onPointerUp   → 分流
```

- 圆心/半径：`_voiceOrbKey` on `Container` 132×132。
- `bool _hitInsideOrb(Offset global)`：`globalToLocal` + 距离 ≤ `radius + slop`。

### 2. 状态

| 变量 | 含义 |
|------|------|
| `_slideToCancel` | 当前指针是否在圆外（UI + 松手判定） |
| `_voiceHoldActive` / `_voiceHoldSeq` | 保留，与异步准备兼容 |

`onPointerMove` 仅在 `_voiceHoldActive || _listening` 时更新 `_slideToCancel`。

### 3. UI

| `_slideToCancel` | 主文案 | 圆边框色 |
|------------------|--------|----------|
| false | 松开结束 | 原 primary / 云状态色 |
| true | 松开取消 | `colorScheme.error` |

可选：取消态 `scale` 略缩小（非必须）。

### 4. 松手逻辑

```dart
void _onVoicePointerUp() {
  _releaseVoiceHold();
  if (_slideToCancel) {
    unawaited(_onVoiceCancel());
  } else {
    unawaited(_onVoiceEnd());
  }
  setState(() => _slideToCancel = false);
}
```

`onPointerCancel`：同取消路径。

准备阶段滑出且尚未 `_listening`：松手仍 `_releaseVoiceHold` + 不 `sendCommand`（`_onVoiceEnd` 早退或走 cancel）。

### 5. 与引擎

- 取消态下若已 `startSession`：`_onVoiceCancel` 已调 `cancelSession`。
- 不在每次 move 出圆时立即 cancel（避免滑回需重启会话）；**仅在松手**时 cancel/end。若实测云 ASR 持续上行 PCM 有问题，可再改为出圆即 cancelSession 并在回圆重启（v2）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 手指移出 Listener 收不到 move | 底部区 Listener 大于圆，仅几何用圆判定 |
| 云 ASR 出圆仍上传 | v1 松手才 cancel；必要时 v2 出圆即 end |
| 与连接中滑出竞态 | 沿用 `_voiceHoldSeq` |

## Migration Plan

- 纯客户端交互；发版即生效。

## Open Questions

- 无（用户已确认：滑回可恢复、以圆为准）。

## Context

主页当前在 Android/iOS 上默认 `HomeInputChannel.voice`，输入模式通过 `HomeInputModeDock` 贴边半圆展示；用户需点击展开三选一菜单（语音 / 文字 / 按钮）再切换。事件按钮模式（`buttons`）已实现完整 add 流程，但路径偏长。Web 端独立由 `WEB_HOME_INPUT` 控制文字或语音，本变更**不修改 Web**。

既有几何：`dockCircleCenterForSnapped` 将圆心落在屏幕边缘线上，形成半圆贴边；位置由 `HomeInputDockStore` 持久化。事件添加 fly 动画（`HomeEventRecordFlyOverlay`）在前 32% 使用 `easeOut` pop 放大，本变更借鉴其 pop 曲线但不做位移飞行。

## Goals / Non-Goals

**Goals:**

- 移动端默认 `buttons`；移除移动端 `text` 主输入。
- Dock 一键轮转 `buttons` ↔ `voice`；松开触发切换；pop 缩放反馈。
- 按下展示完整圆，pop 动画期间保持全圆，结束后回半圆。
- 持久化方案 A：仍保存/恢复 `voice`/`buttons`；`text` 无效 → 默认 `buttons`。
- 语音不可用 Toast 引导切换事件按钮模式。

**Non-Goals:**

- Web 端 `WEB_HOME_INPUT`、文字主输入、Web dock 隐藏规则。
- 自动在 STT 失败时强制切到 buttons（仅文案引导）。
- 删除 `HomeInputChannel.text` 枚举值（保留供 Web 与存储兼容，移动端 UI 不暴露）。
- 改动事件 add、历史 WS、按钮网格业务逻辑。

## Decisions

### 1. 默认与持久化（方案 A）

- `initState` 移动端 `_inputChannel = HomeInputChannel.buttons`（非 Web 且非 Web 强制 text 分支）。
- `_restoreSavedInputChannel`：若 saved 为 `text` 或不可用，跳过；`voice`/`buttons` 仍恢复。
- 新装用户与曾选文字的老用户均落在 `buttons`；曾选语音的用户仍进语音。

**备选**：完全停止 channel 持久化 — 拒绝，因会丢失 voice 偏好。

### 2. 移动端可用 channel 列表

- `_availableChannels`（dock 内）：`[buttons, voice]`，轮转顺序固定 **buttons → voice → buttons**。
- `_isInputChannelAvailable`：`text` 在 `!kIsWeb` 时返回 false。
- `home_screen` 移除移动端 `_buildTextInput` 分支；Web `kIsWeb && text` 路径保留。

### 3. Dock 交互状态机

```
idle (semicircle)
  → pointerDown: animate center to full-circle inset (~150ms easeOut)
  → pointerUp (movement < tapSlop): cycle channel + pop animation (keep full circle)
  → pop complete: animate back to semicircle idle
  → pointerMove > slop: drag mode (collapse expand menu logic removed); panEnd snap
```

- **Tap vs drag**：复用约 12px 位移阈值；拖动时不轮转。
- **轮转时机**：`onPointerUp` 且判定为 tap 时调用 `onChannelSelected(next)`，非 `onPointerDown`。
- 删除 `_expanded`、展开菜单、历史区 dismiss 遮罩。

### 4. 全圆 / 半圆几何

在 `home_input_dock_geometry.dart` 新增 `dockCircleCenterForFullCircle(edge, along, bounds)`：相对半圆圆心沿屏内法向内移 `kHomeInputDockRadius`。

| 边 | 半圆 center | 全圆 center |
|----|-------------|-------------|
| right | `bounds.right` | `bounds.right - radius` |
| left | `bounds.left` | `bounds.left + radius` |
| top | `bounds.top` | `bounds.top + radius` |
| bottom | `bounds.bottom` | `bounds.bottom - radius` |

`AnimatedPositioned` 或 lerp `center` 在 engaged / cycling 与 idle 间过渡。

### 5. Pop 轮转动画

独立 `AnimationController`（建议 320–380ms，`SingleTickerProviderStateMixin`）：

| 参数 | 值 |
|------|-----|
| peakScale | 1.25–1.3 |
| 曲线 | 0–45% `easeOut` 放大；45–100% `easeIn` 缩回 1.0 |
| 图标 | 切换开始时立即更新为新 mode icon |
| 位移 | 无（仅 scale，参考 fly overlay pop 段，不含 fly 段） |

动画期间 dock 保持 **全圆** 位置；`AnimationStatus.completed` 后动画回半圆 center。

### 6. 语音失败文案

| 位置 | 移动端新文案（示例） |
|------|---------------------|
| `home_screen` prepare 失败 | 「语音识别不可用，请切换到事件记录模式」 |
| `home_speech_recognizer` | 同上或「请稍后重试，或使用事件按钮记录」 |

`kIsWeb` 分支保持「文字输入」相关文案不变。

## Risks / Trade-offs

- **[误触轮转]** 用户本想拖动却轻触 → 用 tapSlop 区分；拖动优先不轮转。
- **[移除文字输入]** 无法用自然语言 chat 落库 → 产品接受；Web 仍可用文字。
- **[enum 保留 text]** 存储键仍可能有 `text` → 恢复时忽略即可，无需迁移脚本。
- **[规格 REMOVED 展开菜单]** 归档后基线不再要求 expand dismiss overlay → 实现更简单，与旧截图/文档不一致 → 以新 spec 为准。

## Migration Plan

- 随下一版本 App 发布；无服务端变更。
- 用户升级：saved `text` → 下次进首页为 buttons；saved `voice`/`buttons` 不变。
- 回滚：还原 dock 与 home_screen 分支即可；持久化键兼容。

## Open Questions

（无 — 持久化 A 与全圆时机已在 proposal 前确认。）

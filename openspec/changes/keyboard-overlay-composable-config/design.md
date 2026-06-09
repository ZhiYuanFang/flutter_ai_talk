## Context

App 已在 `app.dart` 挂载全局 `KeyboardInputConfirmBarOverlay` 与 `KeyboardInputBridgeController`（基线见 `keyboard-top-input-confirm-bar`）。`ucg-keyboard-input-enhancements` 为 UCG 五处输入增加了 emoji、多行镜像与 scene detach 策略，但实现存在：浮层高度过大、`TextInput.hide` 误 detach、emoji 入口与场景 UX 不匹配等问题。

产品已明确：不同 scene 需要可组合的浮层能力（emoji / 多媒体 / 浮层输入 / 确定），聊天走微信式 dock（无全局浮层），评论/资料/home.text 等走完整浮层，compose/备注仅 emoji 浮层，登录类无 emoji。所有场景统一「顶组件」而非顶整页。

## Goals / Non-Goals

**Goals:**

- 引入 `KeyboardOverlayConfig` 与 `KeyboardOverlayMetrics`，单一 Bridge + Overlay 按 config 渲染。
- 修复浮层高度、emoji 会话生命周期、键盘/浮层贴合（Android/iOS 同一套 logical px）。
- 实现 scene 配置表（见下）及聊天 dock 内 emoji 面板 + 顶部多媒体预制。
- 浮层 accessory 行：左 accessory → 中输入 → **最右** `confirmLabel`（评论/`home.text` 为「发送」）。
- `showInputField==true` 时页面只读、浮层 TextField 主编辑；否则页面可编辑。
- 顶组件：attach 时注册锚点，`Scrollable.ensureVisible` / 等价逻辑使锚点底边对齐键盘+浮层 chrome 顶缘。

**Non-Goals:**

- 浮层 `showMultimedia` 的首个非聊天业务接入（仅架构与 UI 占位）。
- 自定义贴纸、后端 API 变更、新增 `test/` 自动化。
- 移动端启用 `home.text`（仍仅 Web）。

## Decisions

### 1. `KeyboardOverlayConfig` 取代固定 layout enum

```dart
class KeyboardOverlayConfig {
  final bool showEmoji;
  final bool showMultimedia;
  final bool showInputField;
  final bool showConfirmButton;
  final String confirmLabel; // 默认「确定」
  bool get anyEnabled =>
      showEmoji || showMultimedia || showInputField || showConfirmButton;
}
```

- `anyEnabled == false` → 不渲染全局 Overlay（`ucg.chat`）。
- 页面只读规则：`showInputField == true` → 页面 Field 只读 + hidden/浮层获焦；否则页面可编辑。

**备选**：四套固定 enum — 拒绝，组合爆炸且与 bool 特化需求不一致。

### 2. Scene 默认 config（`resolveOverlayConfig(scene)`）

| scene | emoji | media | input | confirm | label | 页面编辑 | 全局浮层 |
|-------|-------|-------|-------|---------|-------|----------|----------|
| `ucg.chat` | dock | 顶栏预制 | dock | dock发送 | — | 是 | **否** |
| `ucg.compose.body` | ✓ | ✗ | ✗ | ✗ | — | 是 | ✓ |
| `ucg.post.comment` | ✓ | ✗ | ✓ | ✓ | 发送 | 否 | ✓ |
| `ucg.profile.nickname/bio` | ✓ | ✗ | ✓ | ✓ | 确定 | 否 | ✓ |
| `home.text` | ✓ | ✗ | ✓ | ✓ | **发送** | 否 | ✓ |
| `home.history-edit.remark` | ✓ | ✗ | ✗ | ✗ | — | 是 | ✓ |
| `home.number.remark` | ✓ | ✗ | ✗ | ✗ | — | 是 | ✓ |
| `login.*` / `register.*` / `change-password.*` / `baby-bind.*` / `baby-profile.nickname` | ✗ | ✗ | ✗ | ✗ | — | **是** | **否** |

Auth 与宝宝资料类 scene **不得** `showEmoji`，且 **不 attach 全局浮层**（四 bool 全 false），页面 TextField 直接编辑。

### 3. Accessory 行布局

```
[😊?] [📎?] [ Expanded TextField? ] ········· [ confirmLabel ]
 44px 固定行高；confirm 按钮 `minimumSize` 52×36，靠最右。
```

多媒体缩略条在 accessory **之上**（`showMultimedia` 时）。

### 4. `KeyboardOverlayMetrics`（Android/iOS 相同）

| 常量 | 值 |
|------|-----|
| accessoryBarHeight | 44 |
| editorMinHeight / editorMaxHeight | 36 / 72 |
| editorMaxLines | 2 |
| barPadding | H8 V4 |
| emojiPanelMinHeight | 200 |
| emojiPanelHeight | max(200, lastKeyboardInset - 44) |

Material `elevation` 降至 0–1；keyboard 可见时不叠 SafeArea minimum bottom。

### 5. 顶组件（Component lift）

- attach 传入 `GlobalKey` 锚点，**默认锚定用户聚焦的输入框本身**；仅当页面输入与可见编辑区分离时（如资料页 hidden field）才在外部可见区挂同一 key。
- 计算 `overlayChromeHeight = accessory + (emojiMode ? panel : 0) + (mediaStrip ? stripH : 0)`。
- 键盘弹出后 `ensureVisible(anchor, alignment: 1.0, alignmentPolicy: keepVisibleAtEnd)`，视需要加 `padding.bottom = overlayChromeHeight`。
- **不**依赖全页 `resizeToAvoidBottomInset: true` 作为唯一手段；Sheet 可用 `respectKeyboardInset` + 锚点滚动组合。

### 6. 聊天（无全局浮层）

- `UcgInputDock`：行内 `[+] [Field] [😊] [发送]`；emoji 面板在 dock **正下方**，高 ≈ `lastKeyboardInset`。
- Bridge 仍 attach（`InputMode` / `insertAtCursor`），`overlayVisible == false`。
- 多媒体：`onAttach` 选图/视频 → **聊天列表上方预制条**，点「发送」随消息一并发出（非浮层 multimedia）。
- emoji 模式：`TextInput.hide` 后 **不得** detach；焦点保持在 dock Field。

### 7. 底部输入面状态机（`InputTarget` + `BottomSurface`）

**动机**：旧实现用 `_inputMode`、`_restoringKeyboardFromEmoji`、`_blockEmojiPanelUntilMs` 三套布尔/时间窗交叉推导 UI，overlay-primary（昵称/简介）双 FocusNode 下易竞态。改为 **用户意图** 与 **系统 inset 推导展示面** 分离。

#### 7.1 用户意图 `InputTarget`（仅两处写入）

| 入口 | 调用 |
|------|------|
| 左上角 accessory 图标 | `requestKeyboard()` / `requestEmoji()`（由当前 `BottomSurface` 决定切到哪） |
| 浮层/页面输入框 `pointerDown` | `requestKeyboard()` |

- `_target` 默认 `keyboard`；attach / detach 时重置。
- **禁止**在 focus 回调、inset 动画、`_onOverlayFocusChange` 中改写 `_target`。

#### 7.2 展示面 `bottomSurface(rawInset)`（只读推导）

`rawInset` = `readRawViewInsetBottom`（不受 `KeyboardOverlayInsetSync` 合成影响）。

`showEmoji==false` 的 scene（登录/聊天 attach 等）：

| 条件 | surface |
|------|---------|
| `raw > 0` | `systemKeyboard` |
| else | `none` |

`showEmoji==true`：

| `_target` | `raw` | `peakInset` | surface |
|-----------|-------|-------------|---------|
| `emoji` | `≤ 0` | * | `emojiPanel` |
| `emoji` | `> 0` | * | `keyboardPending`（IME 尚未 hide 完，底部白占位） |
| `keyboard` | `> 0` | * | `systemKeyboard` |
| `keyboard` | `≤ 0` | `> 0` | `keyboardPending`（IME 尚未 show 完，底部白占位） |
| `keyboard` | `≤ 0` | `0` | `none` |

`peakInset`：binding 内见过的最大 `rawInset`，emoji 切换时作 monotonic 占位，避免 Sheet 高度震荡。

#### 7.3 Accessory 图标（只读）

```
accessoryShowsKeyboardIcon = showEmoji && bottomSurface != systemKeyboard
```

点击图标：**不看** `_target`，只看当前 surface——展示键盘图标 → `requestKeyboard()`；展示表情图标 → `requestEmoji()`。

#### 7.4 布局与 inset 单源

- **底部 slot**（白底 + 可选 emoji 网格）：`holdsKeyboardSlot` ⇔ surface ∈ `{emojiPanel, keyboardPending}` 或（键盘动画中 `raw < peak - ε`）。
- **Accessory 定位**：有 slot 时 `bottom = peakInset`；`systemKeyboard` 时 `bottom = rawInset`。
- **`effectiveViewInsetBottom`**：slot 或 `raw < peak` 时 `max(raw, peak)`，供 `KeyboardOverlayInsetSync` 合成。
- **`shouldSuppressOutsideDismiss`**：`surface == keyboardPending`（配合 `KeyboardDismissScope` pointerDown 追踪，避免切换瞬间误 dismiss）。

#### 7.5 Emoji 会话生命周期

- `ManagedKeyboardTextField` / attach：`surface ∈ {emojiPanel, keyboardPending}` 或 `_target==emoji` 时 focus 短暂丢失 **不** detach；overlay-primary（`showInputField`）同理。
- 显式 dismiss（空白点击、路由离开、confirm、dispose）才 detach。
- **删除**：`_restoringKeyboardFromEmoji`、`_blockEmojiPanelUntilMs`、多帧 `waitForKeyboard` / `finishRestore`；`requestKeyboard()` 仅 `requestFocus` + `TextInput.show` + notify。

#### 7.6 overlay-primary 单 FocusNode（Phase 2，已实现）

`showInputField==true` 时：

- 页面 **不** 再渲染可编辑/只读 TextField，仅保留 `FocusNode` + attach 锚点（hidden 1×1 或可见 tap 区）。
- 全局浮层 `_OverlayEditor` 为 **唯一** TextField，绑定 `binding.controller` + `binding.focusNode`。
- 删除 `_overlayFocusNode`、`_overlayEditController`、`_lockPageFocusForOverlay`、`_onOverlayFocusChange`。
- emoji↔键盘 与备注/发布同路径：`binding.focusNode.requestFocus()` + `TextInput.show/hide`。

#### 7.7 overlay-primary 浮层可见性 + 评论只读预览（已实现）

- `overlayVisible`：`showInputField==true` 且 `hasBinding` 时 **始终** 渲染浮层 chrome（不依赖 `focusNode.hasFocus`，避免 TextField 未挂载死锁）。
- `ucg.post.comment`：Sheet 内仅只读 `@mention` 预览 + hidden attach；**唯一**可编辑区为浮层 `_OverlayEditor`；mention 原子删除 formatter 经 `KeyboardInputBinding.inputFormatters` 透传。

### 8. Compose / 备注 overlay 不管 blur

`showConfirmButton==false` 且 `showInputField==false` 时，overlay 不执行 confirm/blur 策略；文本由页面 controller 持有。

## Risks / Trade-offs

- **[Risk] 顶组件 + 全局 Overlay 双 inset 计算错误** → Bridge 暴露 `overlayChromeHeight` 单源；Sheet 与 Scaffold 共用。
- **[Risk] 聊天 dock emoji 与旧 spec「仅浮层 emoji」冲突** → 本变更 REMOVED 旧条款，以 `ucg.chat` dock 为准。
- **[Risk] 评论改 fullEditor 后 Sheet 内发送钮与浮层「发送」重复** → 保留 Sheet 发送钮；浮层「发送」等同 `onConfirm`→发送，行为一致。
- **[Trade-off] home.text 仅 Web** → 配置仍写入 `resolveOverlayConfig`，移动端无 attach 路径。

## Migration Plan

1. 扩展 Bridge/Overlay/Metrics + config 解析。
2. 修复 detach/高度/inset（全 scene 受益）。
3. 按 scene 表逐页接入：auth → profile → comment → compose/remarks → chat dock → home.text。
4. 手工回归矩阵：Android + iOS；Web 单独测 `home.text`。
5. 回滚：revert Bridge/Overlay 扩展，恢复 `ucg-keyboard-input-enhancements` 行为。

## Open Questions

- 浮层 `showMultimedia` 首个接入 scene（本迭代可仅 UI 占位）。
- 评论 Sheet 是否在 UI 上隐藏 redundant 发送 IconButton（可选 polish，非阻塞）。

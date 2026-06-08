## Context

UCG 模块已在 `ucg-minimal-visual-system` 中通过 `ManagedKeyboardTextField` 将五处输入（`ucg.chat`、`ucg.compose.body`、`ucg.post.comment`、`ucg.profile.nickname`、`ucg.profile.bio`）接入全局 `keyboardInputBridgeController` 与 `KeyboardInputConfirmBarOverlay`。当前桥接层仅维护 `draftText` 镜像、单行 ellipsis 展示，且 overlay 可见性完全依赖 `MediaQuery.viewInsets.bottom > 0`；`detach()` 不区分场景、不处理失焦未确认策略。资料页仍使用 inline 可见 TextField 切换编辑态。

喂养模块（home、login 等）已稳定使用同一 overlay，本变更采用 **Option B**：在现有 `KeyboardInputBridgeController` + `KeyboardInputConfirmBarOverlay` 上扩展，而非新建平行输入系统。UCG 场景通过 `scene` 字符串驱动差异化行为；喂养模块默认行为保持不变。

基线参考：`openspec/specs/v1.0.1.md` 中 `keyboard-top-input-confirm-bar` capability；变更 delta 见 `ucg-minimal-visual-system` 中 UCG 接入条款。

## Goals / Non-Goals

**Goals:**

- 五处 UCG 受管控输入支持 Unicode emoji 插入（光标处）、键盘/表情面板微信式切换（仅确认条 accessory）。
- 确认条浮动草稿镜像支持多行展示；除昵称与 obscure 场景外，长按草稿弹出「换行」菜单。
- 按 scene 实现失焦未点「确定」的 discard（资料）vs soft-sync（聊天/评论/发布）策略。
- 资料昵称/简介改为隐藏 `ManagedKeyboardTextField` + 静态只读展示，键盘 + 确认条为唯一编辑面。
- 表情面板模式下保持 draft 镜像与「确定」可见（扩展 overlay 可见性条件）。

**Non-Goals:**

- 自定义贴纸、图片表情、emoji 搜索/最近使用面板（首版可用系统 Unicode emoji picker 或轻量 grid）。
- 喂养模块输入行为变更、后端 API 变更。
- 新增自动化测试文件（按仓库规则）。
- TextField / `UcgInputDock` 旁增加 emoji 按钮。

## Decisions

### 1. Option B — 扩展 Bridge + Overlay（非平行系统）

**选择**：在 `KeyboardInputBridgeController` 增加 `InputMode`、`insertAtCursor`、`insertNewlineAtSelection`、按 scene 的 `detachPolicy`；在 `KeyboardInputConfirmBarOverlay` 增加 accessory 行（emoji 切换 + 可选 emoji panel）、多行 draft 区、长按换行菜单。

**理由**：喂养模块已挂载同一 overlay；扩展比 fork 维护成本低，且 UCG 差异可通过 `scene` 前缀 `ucg.` 门控新 UI（emoji toggle 仅对 UCG scene 显示）。

**备选**：Option A 新建 `UcgKeyboardInputOverlay` — 拒绝，会导致双 overlay 竞态与 `MaterialApp` builder 重复挂载风险。

### 2. InputMode 状态机

```text
InputMode.keyboard  ←toggle→  InputMode.emoji
         ↑                              |
         └──────── tap draft / 确定 ────┘
```

- `keyboard`：系统软键盘可见（或 Web 等价）；`viewInsets.bottom > 0` 通常成立。
- `emoji`：收起系统键盘（`FocusNode` 保持绑定、`SystemChannels.textInput` hide），展示 emoji 面板；overlay 仍 visible（见决策 3）。
- Toggle 仅改变 mode，不 `detach`；`draftText` 与 controller 保持同步。
- 从 emoji 切回 keyboard：重新 `requestFocus()` 于绑定 `focusNode`。

### 3. Overlay 可见性扩展

**当前**：`visible = viewInsets.bottom > 0 && hasBinding`

**新规则**：

```dart
visible = hasBinding && (
  viewInsets.bottom > 0 ||
  inputMode == InputMode.emoji
);
```

表情模式下 overlay 底部 padding 使用最近一次 keyboard inset 或固定最小高度，避免跳动。失焦且无 emoji mode 时隐藏。

### 4. insertAtCursor / insertNewlineAtSelection

桥接层新增：

- `insertAtCursor(String text)`：读取 binding.controller.selection，在 collapse 或 range 处 splice，`updateDraft` 新全文，写回 controller（保持 selection 在插入点后）。
- `insertNewlineAtSelection()`：`insertAtCursor('\n')` 的语义别名；scene 为 `ucg.profile.nickname` 或 `obscureText == true` 时 no-op。

Emoji 面板点击 emoji → `insertAtCursor(emoji)`；不经过 IME，直接 UTF-8 写入。

### 5. detach 行为按 scene 拆分

在 `KeyboardInputBinding` 或 attach 参数增加 `BlurWithoutConfirmPolicy`：

| Policy | Scenes | detach 时行为 |
|--------|--------|---------------|
| `discardRestoreSnapshot` | `ucg.profile.nickname`, `ucg.profile.bio` | 恢复 attach 时 `_snapshotText`；不调用 `onConfirm` |
| `softSyncDraft` | `ucg.chat`, `ucg.post.comment`, `ucg.compose.body` | 将 `draftText` 写回 controller；不调用 `onConfirm` |
| `default`（喂养等） | 非 UCG 或 legacy | 保持现有 detach 不清 controller、不触发 onConfirm |

`ManagedKeyboardTextField` 新增可选 `onBlurWithoutConfirm`（profile 用于 UI 退出 editing 态）；detach 前按 policy 执行。

**compose 特例**：soft-sync 仅更新内存 controller；**不得**触发本地草稿文件持久化（该逻辑仍仅在 `onConfirm` / 显式保存路径执行）。

### 6. ManagedKeyboardTextField 隐藏模式

新增 `visibility: ManagedInputVisibility.visible | hidden`：

- `hidden`：Widget 仍参与 focus tree（`Opacity(0)` + 零尺寸或 `Offstage`），用于 profile 昵称/ bio；用户点击资料页「编辑」→ `focusNode.requestFocus()`。
- 资料页头部始终渲染静态 Text；编辑期间不 swap 为可见 TextField。

attach 时 bridge 仍收到 hint/scene/onConfirm；确认条 mirror 为唯一输入反馈（系统键盘输入仍可通过隐藏 field 接收）。

### 7. 确认条 UI 结构

```text
┌─────────────────────────────────────────────┐
│ [😊/键盘 toggle]  │  multiline draft  │ 确定 │
├─────────────────────────────────────────────┤
│ emoji panel (when InputMode.emoji)          │
└─────────────────────────────────────────────┘
```

- Toggle **仅**渲染当 `scene.startsWith('ucg.')`。
- Draft 区：`maxLines` 受限（如 4–6），`TextOverflow.fade` 或 scroll，**不得**再强制 `maxLines: 1` + ellipsis。
- 长按 draft（非 obscure、非 nickname scene）→ `showMenu` → 「换行」→ `insertNewlineAtSelection()`。

### 8. 「确定」行为不变

各 scene 现有 `onConfirm` 映射保持：

- `ucg.chat` → 发送消息
- `ucg.post.comment` → 提交评论
- `ucg.compose.body` → 回填 + 草稿持久化 + unfocus
- `ucg.profile.nickname` / `ucg.profile.bio` → 回填 + `_commitNickname` / `_commitBio`

`confirm()` 仍：draft → controller → onConfirm → unfocus → detach。

### 9. Emoji 面板实现

首版：轻量 `GridView` + 常用 Unicode emoji 子集（或 `emoji_picker_flutter` 若已在 pubspec；否则内嵌静态列表避免新依赖）。无贴纸 Tab。选中即 `insertAtCursor`。

## Risks / Trade-offs

- **[Risk] Web 平台 long-press 菜单不可靠** → 设计 fallback：Web 上 draft 区旁显示小型「换行」icon button（仅非 nickname、非 obscure UCG scene）；移动端仍长按。
- **[Risk] emoji 模式 hide keyboard 导致 focus 丢失** → 保持 `FocusNode` attached，使用 `TextInput.hide` 而非 unfocus；切回 keyboard 时 `requestFocus()`。
- **[Risk] 多行 draft 撑高确认条遮挡内容** → 限制 maxLines + 内部 scroll；emoji panel 高度固定。
- **[Risk] soft-sync 与 compose 草稿文件语义混淆** → 代码审查门控：`_persistDraft` 仅能从 `onConfirm` 或显式保存调用，detach soft-sync 路径不得调用。
- **[Trade-off] UCG-only emoji toggle** → 喂养用户暂无法在 confirm bar 插 emoji；符合 scope，后续可泛化。

## Migration Plan

1. 扩展 bridge API（向后兼容：新参数可选，默认 `default` detach policy）。
2. 更新 overlay UI（喂养 scene 无 emoji toggle，draft 多行对全局生效但行为兼容）。
3. 逐屏接入 UCG：chat → compose → comment → profile（profile UX 变更最大，放最后）。
4. 手工验证五场景 + 喂养 login/home 回归（确认无 emoji toggle、detach 不变）。
5. 回滚：revert bridge/overlay 扩展，UCG 回退到 `ucg-minimal-visual-system` 基线行为。

## Open Questions

- Emoji 面板首版用静态 grid 还是引入 `emoji_picker_flutter` 依赖？（实现阶段按 pubspec 现状决定，规格不绑定具体包。）
- Web draft 换行 fallback 图标是否本迭代必做，还是仅文档化 risk？（建议本迭代做最小 icon fallback。）

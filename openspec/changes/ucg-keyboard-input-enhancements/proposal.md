## Why

UCG 模块已在 `ucg-minimal-visual-system` 中完成五处受管控输入（聊天、发布正文、帖子评论、资料昵称/简介）对 `keyboard-top-input-confirm-bar` 的基础接入，但尚不支持 Unicode 表情插入、键盘/表情面板切换、多行草稿镜像与换行、以及各场景差异化的失焦（未点「确定」）策略；资料页仍采用 inline TextField 可见编辑，与「键盘 + 确认条为唯一编辑面」的产品预期不符。需要在不改动喂养模块的前提下，统一增强 UCG 键盘输入体验并补齐规格与实现契约。

## What Changes

- 五处 UCG 受管控输入场景（`ucg.chat`、`ucg.compose.body`、`ucg.post.comment`、`ucg.profile.nickname`、`ucg.profile.bio`）均支持在光标处插入 Unicode emoji；表情切换入口**仅**位于键盘顶部确认条 accessory，不在 TextField 旁或 `UcgInputDock` 上增加按钮。
- 确认条 accessory 提供微信式键盘 ↔ 表情面板切换；表情面板模式下仍展示浮动草稿镜像与「确定」按钮（可见性规则扩展至不仅依赖 `viewInsets`）。
- 浮动草稿镜像支持多行展示（非单行省略）；除昵称场景外，长按草稿镜像弹出菜单「换行」，在选区插入换行符；密码/obscure 场景排除换行菜单。
- **资料编辑 UX 变更**：昵称/简介点击编辑后，资料页头部保持静态只读展示；编辑由隐藏的 `ManagedKeyboardTextField` 聚焦驱动，键盘 + 确认条为唯一可见编辑界面（**不再** inline 可见 TextField 切换）。
- **失焦未点「确定」策略分场景**：
  - 资料昵称/简介：丢弃草稿，恢复编辑开始时的快照，**不**调用 `onConfirm`。
  - 聊天、评论、发布正文：将 `draftText` 软同步回 controller/可见字段，**不**丢弃、**不**调用 `onConfirm`；发布正文失焦未确定**不**写入本地草稿文件。
- 扩展 `KeyboardInputBridgeController` 与 `KeyboardInputConfirmBarOverlay`（Option B 架构）：`InputMode` 状态机、 `insertAtCursor` / `insertNewlineAtSelection` 辅助方法、按 scene 拆分的 detach 行为；可选 `ManagedKeyboardTextField` 隐藏模式与 `onBlurWithoutConfirm` 回调。
- 不引入自定义贴纸包；emoji 以 UTF-8 纯文本经现有 API 提交。喂养模块键盘输入行为保持不变。

## Capabilities

### New Capabilities

- `ucg-emoji-input`：UCG 受管控输入的 Unicode emoji 插入、键盘/表情面板切换、表情模式下确认条可见性、以及确认条 accessory 交互契约。

### Modified Capabilities

- `keyboard-top-input-confirm-bar`：多行草稿镜像、长按换行菜单、emoji 切换 accessory、表情模式可见性扩展、按 scene 的 detach 软同步/丢弃策略。
- `managed-keyboard-textfield`：隐藏编辑模式、`onBlurWithoutConfirm`、与 bridge 插入 API 的协作。
- `ucg-chat-ui`：聊天输入 emoji/换行/失焦软同步行为。
- `ucg-compose-post`：发布正文 emoji/换行/失焦软同步（不写本地草稿）行为。
- `ucg-profile`：昵称/简介隐藏输入编辑 UX、失焦丢弃策略、昵称禁止换行。

## Impact

- **Flutter**：`app/lib/ui/widgets/keyboard_input_bridge.dart`（或同级桥接层）、`keyboard_input_confirm_bar_overlay.dart`、`managed_keyboard_text_field.dart`；`app/lib/ucg/ui/ucg_chat_screen.dart`、`ucg_compose_screen.dart`、`ucg_post_detail_screen.dart`、`ucg_profile_screens.dart` 及关联 widget。
- **OpenSpec**：基于 `ucg-minimal-visual-system` 与 `add-ucg-module` 中已有 keyboard/managed-input 条款进行 MODIFIED delta；新增 `ucg-emoji-input` 能力规格。
- **不在范围**：喂养模块 UI 与键盘 overlay、自定义贴纸/图片表情、后端 API 变更、自动测试文件（按仓库规则不新增 `test/`）。

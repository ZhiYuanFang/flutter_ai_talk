## 1. 桥接层扩展（KeyboardInputBridgeController）

- [x] 1.1 在 `keyboard_input_bridge.dart` 增加 `InputMode`（keyboard / emoji）状态及 `notifyListeners` 更新路径
- [x] 1.2 增加 `BlurWithoutConfirmPolicy` 枚举（default / discardRestoreSnapshot / softSyncDraft）并在 `attach` 时按 scene 解析默认策略
- [x] 1.3 实现 `insertAtCursor(String text)` 与 `insertNewlineAtSelection()`（nickname scene 与 `obscureText` 时换行为 no-op）
- [x] 1.4 attach 时保存 `_snapshotText`；重构 `detach()` 在清除 binding 前按 policy 执行 discard 或 soft-sync
- [x] 1.5 确保 `confirm()` 行为不变：draft → controller → onConfirm → unfocus → detach

## 2. 确认条 Overlay（KeyboardInputConfirmBarOverlay）

- [x] 2.1 扩展可见性条件：`hasBinding && (viewInsets > 0 || inputMode == emoji)`
- [x] 2.2 草稿镜像改为多行展示（限定 maxLines + 可滚动），移除强制单行 ellipsis
- [x] 2.3 为 `scene.startsWith('ucg.')` 增加 accessory 键盘 ↔ emoji toggle（微信式）
- [x] 2.4 实现 emoji 面板 UI（Unicode grid，无贴纸）；选中项调用 `insertAtCursor`
- [x] 2.5 长按草稿弹出「换行」菜单（排除 `ucg.profile.nickname` 与 obscure）；Web 增加最小 icon fallback
- [x] 2.6 emoji 模式切换时正确处理 focus（hide keyboard 不 detach，切回 keyboard 时 `requestFocus`）

## 3. ManagedKeyboardTextField 增强

- [x] 3.1 增加 `ManagedInputVisibility`（visible / hidden）与 hidden 渲染（Offstage/零尺寸，仍参与 focus）
- [x] 3.2 增加 `onBlurWithoutConfirm` 回调；detach 路径在 policy 执行后调用
- [x] 3.3 attach 时向 bridge 传递 scene 对应 blur policy
- [x] 3.4 验证喂养模块现有 visible 字段行为回归（default policy、无 emoji toggle）

## 4. UCG 聊天（ucg.chat）

- [x] 4.1 确认 `ucg_chat_screen` / `UcgInputDock` 消息输入 scene 为 `ucg.chat`，dock 无 emoji 按钮
- [x] 4.2 验证 emoji 插入、长按换行、失焦 soft-sync（不发送）、确定发送行为

## 5. UCG 发布（ucg.compose.body）

- [x] 5.1 确认 `ucg_compose_screen` 正文 `ManagedKeyboardTextField` scene 与 blur policy 为 soft-sync
- [x] 5.2 审计 detach/失焦路径不得调用本地草稿持久化；仅 `onConfirm` 触发 `_persistDraft`（或等效）
- [x] 5.3 验证 emoji、换行、失焦 soft-sync、确定保存草稿行为

## 6. UCG 帖子评论（ucg.post.comment）

- [x] 6.1 确认 `ucg_post_detail_screen` 评论输入 scene 为 `ucg.post.comment`，blur policy 为 soft-sync
- [x] 6.2 验证 emoji 插入、换行、失焦 soft-sync（不提交评论）、确定提交评论行为

## 7. UCG 资料（ucg.profile.nickname / ucg.profile.bio）

- [x] 7.1 重构 `ucg_profile_screens` / `ucg_shell`：昵称与简介改为 hidden `ManagedKeyboardTextField`，头部静态只读展示
- [x] 7.2 点编辑 → `requestFocus()` hidden 字段；`onBlurWithoutConfirm` 退出 editing UI 态
- [x] 7.3 昵称 scene 禁用换行菜单；简介允许换行
- [x] 7.4 验证失焦 discard 恢复快照且不调用 commit；确定仍触发 `_commitNickname` / `_commitBio`

## 8. 手工验证与收尾

- [x] 8.1 五场景手工路径：emoji toggle、表情模式确认条可见、多行 draft、换行、blur/确定策略
- [x] 8.2 喂养模块回归：home/login 输入确认条无 emoji toggle，detach 行为与变更前一致
- [x] 8.3 运行 `openspec validate ucg-keyboard-input-enhancements`（若 CLI 支持）并修复规格/任务勾选一致性

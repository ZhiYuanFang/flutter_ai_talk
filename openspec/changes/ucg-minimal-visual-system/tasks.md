## 1. 基础组件与 Scaffold

- [x] 1.1 新增 `ManagedKeyboardTextField`（`app/lib/ui/widgets/managed_keyboard_text_field.dart`），封装 attach/detach/updateDraft/onConfirm
- [x] 1.2 将 `UcgShellGlassCard` 改为轻表面实现（`UcgSurfaceCard`：无 blur/渐变/阴影），保留过渡期 typedef 或批量重命名
- [x] 1.3 `UcgScaffold` 默认 `resizeToAvoidBottomInset: false`
- [x] 1.4 重构 `UcgGlassBottomDock` → `UcgBottomDock`：全宽扁平、轻量选中、发布槽同构无渐变
- [x] 1.5 重构 `UcgGlassInputDock` → `UcgInputDock`：扁平条 + 内部 `ManagedKeyboardTextField` + flat 发送按钮
- [x] 1.6 简约化 `UcgInteractionChip`：去掉 Stadium 描边胶囊，改为轻量 icon+文字

## 2. 广场 Feed 与底栏

- [x] 2.1 `UcgMasonryFeedCard` 改用 `UcgSurfaceCard`（padding 10、radius 12）
- [x] 2.2 `ucg_shell.dart` 底栏调用改为 `UcgBottomDock`
- [x] 2.3 确认广场 `_InlineFeedTab` 选中态无底色 pill（若仍有则移除）

## 3. 消息、我的、发布页视觉迁移

- [x] 3.1 `ucg_messages_tab.dart` 会话行去掉玻璃卡，改简约列表行/轻表面
- [x] 3.2 `ucg_shell.dart` 我的页资料卡、绑定提示卡改用 `UcgSurfaceCard` 或 L0 分区
- [x] 3.3 `ucg_profile_screens.dart` 相关玻璃卡替换为轻表面
- [x] 3.4 `ucg_compose_screen.dart` 表单分区去玻璃卡，改轻表面/裸 shell 分区
- [x] 3.5 `ucg_square_tab.dart` 单列 Moments 路径（若仍 `wrapInShellCard`）改轻表面

## 4. 键盘桥接全量接入（UCG）

- [x] 4.1 聊天页 `UcgInputDock` 确认 `onConfirm` 映射 `_send`（依赖 1.5）
- [x] 4.2 发布页正文 `ManagedKeyboardTextField`：`onConfirm` 收起键盘并 `_persistDraft`
- [x] 4.3 我的页昵称/简介 inline `TextField` 改 `ManagedKeyboardTextField`，`onConfirm` 映射 commit 逻辑
- [x] 4.4 详情评论：Sheet 改 flat（非 glass）、`respectKeyboardInset: false`、评论框接 bridge、`onConfirm` 发送评论
- [x] 4.5 盘点 `app/lib/ucg/**` 无遗漏 `TextField`（应仅上述五处）

## 5. 聊天与其它扫尾

- [x] 5.1 `ucg_chat_screen.dart` 消息泡旁玻璃卡（若有）改轻表面
- [x] 5.2 确认 `UcgPostDetailScreen` 背景氛围 blur 保留、内容区无圆角玻璃卡
- [x] 5.3 清理废弃 `UcgGlass*` 命名与未使用 import（可选 typedef 移除）

## 6. 验证

- [x] 6.1 手工路径：五栏切换、发布、广场 Feed 卡片、详情评论、聊天发送、资料编辑
- [x] 6.2 手工路径：聚焦各输入框时键盘顶部确认条出现、主界面不顶起、点确定行为正确
- [x] 6.3 浅色/暗色 shell 主题下目视检查轻表面对比度与选中态

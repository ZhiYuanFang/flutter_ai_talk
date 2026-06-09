## 1. Bridge 与 Metrics 基础

- [x] 1.1 在 `keyboard_input_bridge.dart` 增加 `KeyboardOverlayConfig`、`resolveOverlayConfig(scene)` 与 `overlayChromeHeight`
- [x] 1.2 增加 `KeyboardOverlayMetrics` 常量；Overlay 移除硬编码 40/120/220
- [x] 1.3 实现 `anyEnabled==false` 时不渲染全局 Overlay
- [x] 1.4 修复 emoji 模式 `TextInput.hide` 不误 detach；记录并使用 `lastKeyboardInset`
- [x] 1.5 实现 accessory 行布局：左 emoji/多媒体 → 中输入 → 最右 `confirmLabel`
- [x] 1.6 重构 Bridge：`InputTarget` + `bottomSurface(raw)` 取代 `_inputMode` / restoring / block 时间窗；`requestKeyboard` / `requestEmoji` 单入口
- [x] 1.7 overlay-primary 单 FocusNode：浮层 `_OverlayEditor` 唯一 TextField；移除双 FocusNode / page focus lock / overlay 失焦 detach
- [x] 1.8 overlay-primary 浮层 `hasBinding` 可见性门闩；评论 Sheet 只读预览 + 浮层唯一输入；binding 透传 `inputFormatters`
- [x] 1.9 修复 emoji↔键盘：skip detach、`requestKeyboard` 统一路径；修复 stale postFrame `requestKeyboard` 覆盖 emoji 切换
- [x] 1.10 评论 Sheet 彻底移除自带输入框 chrome，仅依赖全局浮层输入（`UcgMentionComposerFieldWithHighlight` 支持 `showPreview=false`）

## 2. 浮层 UI 与顶组件

- [x] 2.1 将 `_DraftMirror` 替换为可编辑浮层 TextField（`showInputField` 时）
- [x] 2.2 实现多媒体缩略条占位 UI（`showMultimedia`，可无 scene 接入）
- [x] 2.3 实现顶组件锚点注册与 `ensureVisible` 滚动逻辑
- [x] 2.4 修复浮层高度/ inset / elevation（Android + iOS 一致）

## 3. ManagedKeyboardTextField

- [x] 3.1 透传 `KeyboardOverlayConfig`；`showInputField` 时页面 readOnly + 浮层获焦
- [x] 3.2 注册 anchor Key 供顶组件使用

## 4. Auth / 资料 / Web home.text

- [x] 4.1 登录/注册/改密/绑定/宝宝资料：页面内直接输入（无全局浮层）
- [x] 4.2 资料昵称/简介：底部 Sheet composer（与评论同布局）+ emoji 在输入框左侧，键盘顶 composer
- [x] 4.3 `home.text`（Web）：页面内 composer + emoji（待 Web 回归）

## 5. UCG 发布与评论

- [x] 5.1 `ucg.compose.body`：仅 emoji 浮层，页面正文可编辑
- [x] 5.2 `ucg.post.comment`：页面内 composer + emoji +「发送」；标题固定，键盘仅顶 composer

## 6. 喂养备注

- [x] 6.1 `home.history-edit.remark` / `home.number.remark`：仅 emoji 浮层，页面可编辑，Sheet inset + 顶组件

## 7. UCG 聊天（无全局浮层）

- [x] 7.1 `UcgInputDock`：四 config false；emoji 在输入框左侧；dock 下 emoji 面板（高 ≈ 键盘）
- [x] 7.2 聊天顶部多媒体预制条；点发送才发出
- [x] 7.3 聊天 dock `keyboardDockBottomInset`：键盘顶起 dock，不顶标题
- [x] 7.4 聊天消息列表：键盘/emoji 改变可视高度时 scroll 补偿（读历史保位）；贴底时跟滚到底

## 8. 回归

- [ ] 8.1 Android：compose emoji、评论发送、聊天 dock emoji、登录无 emoji、浮层高度
- [ ] 8.2 iOS：同上
- [ ] 8.3 Web：`home.text` 浮层「发送」
- [x] 8.4 运行 `openspec validate keyboard-overlay-composable-config`

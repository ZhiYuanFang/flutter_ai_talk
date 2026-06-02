## 1. 默认输入模式与 channel 可用性

- [x] 1.1 `home_screen.dart`：移动端 `initState` 默认 `_inputChannel = buttons`（保留 Web text 分支）
- [x] 1.2 `_restoreSavedInputChannel`：持久化 `text` 视为无效并跳过；`voice`/`buttons` 仍恢复（方案 A）
- [x] 1.3 `_isInputChannelAvailable`：移动端 `text` 返回 false；dock 可用列表仅为 `[buttons, voice]`
- [x] 1.4 移除移动端 `_buildPrimaryHomeInput` / 底栏对 `text` 的分支（Web 保留 `_buildTextInput`）

## 2. Dock 几何与交互状态机

- [x] 2.1 `home_input_dock_geometry.dart`：新增全圆内移圆心计算（相对半圆沿屏内法向 offset radius）
- [x] 2.2 `home_input_mode_dock.dart`：删除 `_expanded`、展开菜单、dismiss 遮罩及相关布局
- [x] 2.3 贴边半圆点击仅滑出整圆；整圆（贴边/悬浮）点击切换模式；吸附后重置半圆
- [x] 2.4 轮转顺序固定 `buttons → voice → buttons`，调用既有 `onChannelSelected`

## 3. Pop 轮转动画

- [x] 3.1 新增 `AnimationController`（~320–380ms）：peakScale ~1.25，`easeOut` 放大 + `easeIn` 缩回
- [x] 3.2 松开轮转时立即更新图标为新 mode，pop 期间保持全圆位置
- [x] 3.3 pop 完成后动画回贴边半圆 idle；与 channel 切换触发的 `_scheduleHistoryReanchorAfterInputModeChange` 协调

## 4. 语音失败文案（移动端）

- [x] 4.1 `home_screen.dart`：prepare 失败 Toast 改为引导事件按钮模式（`!kIsWeb`）
- [x] 4.2 `home_speech_recognizer.dart`：失败 message 同步（Web 文案不变）

## 5. 注释与持久化语义

- [x] 5.1 更新 `home_input_channel.dart`、`home_input_channel_store.dart` 注释：移动端 UI 仅 voice/buttons
- [x] 5.2 确认 `HomeInputChannelStore` 仍在轮转后正确 save `voice`/`buttons`

## 6. 验证

- [x] 6.1 Android/iOS 冷启动（无持久化）：默认事件网格；dock 半圆为 grid 图标
- [x] 6.2 松开 dock：voice ↔ buttons 轮转 + pop 动画；全圆 → 半圆
- [x] 6.3 拖动 dock：圆外缘进入吸附带则贴边半圆；否则自由悬浮整圆
- [x] 6.4 持久化 `text` 升级后进入为 buttons；持久化 `voice` 仍为语音
- [x] 6.5 Web 行为不变（text-only 无 dock；voice Web 仍可 text）
## 7. 未绑定宝宝时锁定按钮模式

- [x] 7.1 未绑定宝宝（`needsDeviceBind`）时隐藏输入模式悬浮球
- [x] 7.2 未绑定宝宝时强制 `_inputChannel = buttons`，禁止切换语音

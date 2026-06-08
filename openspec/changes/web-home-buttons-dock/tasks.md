## 1. 移除 WEB_HOME_INPUT

- [x] 1.1 删除 `app/lib/config/web_home_input_mode.dart` 及 `home_screen.dart` 中所有 `_webHomeInputMode` / `resolveWebHomeInputMode` 引用
- [x] 1.2 更新 `app/README.md`：移除 `WEB_HOME_INPUT` dart-define 说明，改为 Web 默认 buttons + dock 切换 text

## 2. HomeInputModeDock 平台化轮转

- [x] 2.1 `HomeInputModeDock` 新增 `dockCycleChannels` 参数，用其驱动 `_availableChannels` / `_nextChannel`（移除或替换 `showButtonsOption` 布尔）
- [x] 2.2 `HomeScreen` 传入：Mobile `[buttons, voice]`，Web `[buttons, text]`

## 3. HomeScreen 平台门禁

- [x] 3.1 全平台 `_inputChannel` 初始值改为 `buttons`；Web 上 `_isInputChannelAvailable` 允许 `buttons`/`text`，拒绝 `voice`
- [x] 3.2 `_canSwitchInputMode` 在 Web 恒为 true；删除 `_showButtonsInputMode => !kIsWeb` 及相关 Web 特例
- [x] 3.3 `_restoreSavedInputChannel`：Web 恢复 `buttons`/`text`，`voice` 回退 `buttons`；删除 Web text-only 拒绝分支
- [x] 3.4 确认 `blockHomeInputChrome` 时仍强制 buttons 并隐藏 dock（游客/未绑宝宝，与 App 一致）

## 4. 验证

- [x] 4.1 Web：`flutter run -d chrome` 冷启动见事件网格；dock 切 text，Enter/提交 NLU 可用；dock 切回 buttons；点事件走 number/time/one 分支
- [x] 4.2 Web：游客/未绑宝宝仅 buttons、无 dock
- [x] 4.3 Android/iOS 回归：默认 buttons，dock voice ↔ buttons 不变

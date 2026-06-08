## REMOVED Requirements

### Requirement: Web 主输入模式全局配置项

**Reason**: Web 主输入改由事件按钮默认 + dock 切换文字承担；`WEB_HOME_INPUT` dart-define 与 `WebHomeInputMode` 枚举已无存在必要，且 `voice` 模式在 Web 上不可用。

**Migration**: 删除 `--dart-define=WEB_HOME_INPUT=...` 构建参数及 `app/lib/config/web_home_input_mode.dart`。Web 冷启动默认展示事件按钮网格；需文字输入时通过 dock 切换到 text 模式。移动端行为不受影响。

### Requirement: 默认 Web 文本模式

**Reason**: Web 默认主输入已与 Android/iOS 对齐为事件按钮，不再默认文本输入框。

**Migration**: 同「Web 主输入模式全局配置项」；README 中 Web 主输入说明改为 buttons 默认 + dock 切换 text。

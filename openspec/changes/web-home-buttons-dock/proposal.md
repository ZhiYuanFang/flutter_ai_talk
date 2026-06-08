## Why

Web 端主页当前默认文字输入，且通过 `WEB_HOME_INPUT` 在 text/voice 间切换；事件按钮网格被 `kIsWeb` 硬禁用，无法在浏览器中像 App 一样点选事件记录喂养。Web 测试与日常使用时无法验证按钮路径、二级事件选择与备注快捷标签等能力；`WEB_HOME_INPUT=voice` 在 Web 上实际不可用，增加配置复杂度却无收益。需将 Web 与 App 对齐：默认事件按钮，dock 在 buttons 与 text 间轮转，并移除 `WEB_HOME_INPUT`。

## What Changes

- **Web 默认输入模式**：冷启动与无有效持久化时，Web 主页 MUST 与 Android/iOS 一致，默认展示**事件按钮网格**（`HomeInputChannel.buttons`）。
- **Web dock 轮转**：已登录且已绑宝宝时，贴边 dock MUST 在 **buttons ↔ text** 间轮转（不得包含 voice）。
- **游客/未绑宝宝**：与 App 一致，仅展示 buttons，隐藏 dock，不得切换到 text。
- **移除 `WEB_HOME_INPUT`**：**BREAKING** 删除 `web_home_input_mode.dart`、`WebHomeInputMode` 枚举及 README 中 `--dart-define=WEB_HOME_INPUT=...` 文档；Web 不再支持编译期 text/voice 主输入开关。
- **持久化**：Web 恢复 `buttons` 或 `text`；持久化为 `voice` 时 MUST 视为无效并回退 `buttons`。
- **dock 组件**：`HomeInputModeDock` 改为接收显式轮转 channel 列表，以区分移动端 `[buttons, voice]` 与 Web `[buttons, text]`。

## Capabilities

### New Capabilities

（无新增独立能力；行为归入既有主页输入相关能力。）

### Modified Capabilities

- `home-button-input-mode`：Web 端 MUST 默认启用事件按钮主输入，与 Android/iOS 对齐；修订原「Web 继续遵循 web-home-input-mode、不修改 Web 行为」条款。
- `home-input-mode-dock`：Web 端 dock MUST 在 buttons 与 text 间轮转且默认显示（非 block 状态）；修订原「Web text-only 不显示 dock」「Web 规则不变」条款。
- `web-home-input-mode`：**BREAKING** 废弃 `WEB_HOME_INPUT` 与 Web 默认 text/voice 策略；Web 主输入改由 buttons 默认 + dock 切换 text 承担。

## Impact

- **Affected code**：`app/lib/ui/home_screen.dart`、`app/lib/ui/home_input_mode_dock.dart`；删除 `app/lib/config/web_home_input_mode.dart`；更新 `app/README.md`。
- **构建参数**：移除 `WEB_HOME_INPUT` dart-define（**BREAKING**）；现有 CI/本地脚本若引用该参数需删除。
- **规格基线**：MODIFIED `openspec/specs/v1.0.1.md` 中 `home-button-input-mode`、`home-input-mode-dock`、`web-home-input-mode` 相关 Requirement。
- **测试**：Web 冷启动见事件网格、dock 切 text、NLU 提交、按钮记事件与二级 picker；游客/未绑宝宝仅 buttons；移动端回归 voice ↔ buttons 不变。

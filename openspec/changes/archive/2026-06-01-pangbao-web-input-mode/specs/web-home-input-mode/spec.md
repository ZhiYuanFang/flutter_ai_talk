## ADDED Requirements

### Requirement: Web 主输入模式全局配置项

The system SHALL expose exactly one project-wide configuration that determines whether the Flutter Web build uses text-field primary input or press-and-hold speech-to-text primary input on the home screen. 该配置仅在 `kIsWeb` 为真时参与主页主输入分支选择；在 Android/iOS 等非 Web 目标上，应用必须忽略该配置且不改变现有语音球行为。配置项必须可通过单一源码位置或构建期 `dart-define`（由实现选定并在 README 中说明）解析，不得在多个无关文件中重复硬编码互不一致的默认值。

#### Scenario: 非 Web 忽略配置

- **WHEN** 应用在 Android 或 iOS 上运行
- **THEN** 主页主输入必须仍为按住说话语音球，且不得因 Web 输入模式配置而展示 Web 专用文本框作为主输入

#### Scenario: Web 文本模式主输入

- **WHEN** 用户在 Web 上打开主页且配置为文本模式
- **THEN** 系统必须展示与当前实现一致的文本输入与显式提交路径

#### Scenario: Web 语音模式主输入

- **WHEN** 用户在 Web 上打开主页且配置为语音模式且语音识别可用
- **THEN** 系统必须展示与移动端一致的按住开始、松手结束的语音主输入，并在松手后以转写文本为载荷调用指令动作

### Requirement: 默认 Web 文本模式

The default effective Web home input mode for production builds SHALL be text unless explicitly overridden by the documented configuration mechanism. 未设置任何覆盖时，Web 主输入必须与变更前行为一致（文本输入 + 显式提交），不得默认启用语音采集。

#### Scenario: 未覆盖时保持文本主输入

- **WHEN** 使用默认配置构建并运行 Web
- **THEN** 主页不得将语音采集作为主输入路径

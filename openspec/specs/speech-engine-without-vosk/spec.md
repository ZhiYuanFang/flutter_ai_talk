## ADDED Requirements

### Requirement: 移除 Vosk 引擎选项

The system MUST NOT ship, register, or offer Vosk on-device ASR in the client. 客户端**不得**再打包、注册或提供 Vosk 端侧语音识别；必须移除 `vosk_flutter_service`、内置 Vosk 模型 assets 及相关识别实现。

#### Scenario: 设置页引擎列表

- **WHEN** 用户在 Android 或 iOS 设置中心查看语音识别引擎选项
- **THEN** 列表**不得**包含「本地识别 / Vosk」；必须仅包含云端识别与系统识别（及平台既有默认可选项）

#### Scenario: 安装包体积

- **WHEN** 构建 release 安装包
- **THEN** 产物**不得**再包含 `vosk-model-small-cn-0.22.zip` 或等价 Vosk 模型资源

### Requirement: 旧 Vosk 偏好迁移

The system SHALL migrate persisted `speech_engine=vosk` to a supported engine on load. 当本地 prefs 中语音识别引擎为已废弃的 `vosk` 时，系统必须在读取时迁移：Android 写回 **云端识别**（`cloudAsr`），iOS 写回 **系统识别**（`systemStt`），并持久化新值。

#### Scenario: 升级后首次启动

- **WHEN** 用户从含 Vosk 的旧版本升级并冷启动
- **THEN** 系统不得崩溃或停留在无效引擎；按住说话必须使用迁移后的引擎路径

### Requirement: 语音不可用时不阻塞非语音功能

The system MUST allow text input and non-voice features when the selected speech engine is unavailable. 当云端或系统 STT 不可用时，系统必须仍允许文字输入与其它非语音功能；**不得**因移除 Vosk 而阻止登录、历史浏览或设置。

#### Scenario: 云端未连接

- **WHEN** 用户选择云端识别但 WebSocket 未就绪
- **THEN** 主页必须提示连接状态并允许切换文字输入或系统识别（若平台可用）

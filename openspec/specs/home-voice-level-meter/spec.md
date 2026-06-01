## ADDED Requirements

### Requirement: 聆听中显示多柱响度

The system SHALL show a multi-bar loudness meter at the top-right of the home voice input area only while `_listening` is true. 系统必须在主页语音输入区**右上方**显示**多柱**响度指示器，且**仅当** `_listening == true`（已开始本次采集/聆听）时可见；`_voiceHoldActive` 但尚未进入 `_listening` 时**不得**显示。

#### Scenario: 开录后显示电平柱

- **WHEN** 用户按住说话且 `HomeScreen` 已将 `_listening` 设为 true
- **THEN** 输入区右上方必须出现多柱响度组件

#### Scenario: 非聆听中隐藏

- **WHEN** 用户未处于 `_listening`（含松手后、取消后、仅连接准备中）
- **THEN** 响度柱必须不可见

### Requirement: 真实麦克风电平驱动

The system MUST drive bar heights from real microphone loudness for cloud ASR, Vosk, and system STT engines. 柱高必须由**真实**麦克风电平驱动：云端 ASR 与 Vosk 从 PCM 流计算响度；系统 STT 必须使用 `speech_to_text` 的 `onSoundLevelChange`（或等价真电平 API），**不得**使用随机或固定节奏的假动画。

#### Scenario: 说话时段柱随音量升高

- **WHEN** 用户在 `_listening` 期间对麦克风说话且引擎正常采集
- **THEN** 多柱高度必须随说话音量增大而升高（经平滑后可见变化）

#### Scenario: 静音时柱保持低位

- **WHEN** 用户处于 `_listening` 但环境静音
- **THEN** 柱高必须处于低位（允许最小可见高度，但不得虚假剧烈跳动）

### Requirement: 取消态 error 色联动

The system SHALL use the theme error color scheme for the level bars when slide-to-cancel is active (`_slideToCancel`). 当滑出语音圆取消态（`_slideToCancel == true`）且仍处于 `_listening` 时，响度柱的颜色必须切换为与语音圆取消态一致的 **error** 色系；柱高仍必须随响度变化。取消态解除后必须恢复为正常聆听配色。

#### Scenario: 滑出圆外柱变 error 色

- **WHEN** 用户正在 `_listening` 且指针在语音圆外（`_slideToCancel` 为 true）
- **THEN** 响度柱必须使用 `ColorScheme.error`（或等价 error 色阶）绘制

#### Scenario: 滑回圆内恢复常色

- **WHEN** 用户仍在 `_listening` 但 `_slideToCancel` 恢复为 false
- **THEN** 响度柱必须恢复为正常聆听态配色（非 error）

### Requirement: 结束聆听后重置

The system SHALL hide the meter and reset level state when listening ends. 当 `_listening` 变为 false（正常结束、取消、会话失败清理）时，系统必须隐藏响度柱并将内部电平状态重置，避免影响下一轮按住说话。

#### Scenario: 松手结束后隐藏

- **WHEN** 用户结束本次按住（发送或取消）且 `_listening` 变为 false
- **THEN** 响度柱必须立即隐藏

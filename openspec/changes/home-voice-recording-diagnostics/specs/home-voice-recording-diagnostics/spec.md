## ADDED Requirements

### Requirement: 设置开关默认关闭

The system SHALL provide a persisted settings toggle for recording diagnostics that defaults to off. 系统必须在设置页提供「显示录音数据」开关，持久化存储，且**默认值为关闭**。

#### Scenario: 首次安装未开启

- **WHEN** 用户从未修改该设置
- **THEN** 主页不得显示录音诊断面板

#### Scenario: 用户开启后持久化

- **WHEN** 用户在设置中打开「显示录音数据」并返回主页
- **THEN** 在满足云端聆听条件时必须能够显示诊断面板，且重启应用后仍保持开启

### Requirement: 仅云端 ASR 且聆听中显示

The system MUST show the recording diagnostics panel only when the speech engine is cloud ASR and `_listening` is true. 录音诊断面板**仅当**当前语音识别引擎为**云端 ASR**、且 `_listening == true` 时显示；Vosk 或系统 STT 下**即使**开关打开也**不得**显示。

#### Scenario: 云端聆听中显示

- **WHEN** 开关已开启、引擎为云端 ASR、用户处于 `_listening`
- **THEN** 语音圆左侧必须显示诊断信息

#### Scenario: Vosk 下不显示

- **WHEN** 开关已开启但引擎为 Vosk 且 `_listening` 为 true
- **THEN** 不得显示录音诊断面板

#### Scenario: 未聆听不显示

- **WHEN** 开关已开启但 `_listening` 为 false
- **THEN** 不得显示录音诊断面板

### Requirement: 诊断字段内容

The system SHALL display format, sample rate, chunk and session avgAbs, and elapsed seconds for cloud PCM capture. 面板必须展示：**格式**（PCM16）、**采样率**（16000 Hz）、**块级 avgAbs**、**会话 avgAbs**、**时长**（秒，至少一位小数）；数值必须来自真实 PCM 采集，不得使用假数据。

#### Scenario: 块级与会话 avgAbs 同时展示

- **WHEN** 用户在云端 `_listening` 中说话且 PCM 块持续到达
- **THEN** 面板必须同时显示当前块 avgAbs 与会话累计 avgAbs，且二者可不同

#### Scenario: 时长递增

- **WHEN** 用户持续按住聆听超过 1 秒
- **THEN** 时长读数必须随时间递增

### Requirement: 不干扰语音手势

The diagnostics overlay MUST NOT block voice orb pointer handling. 诊断面板必须使用 `IgnorePointer`（或等价方式），不得阻挡语音圆按住、滑出取消等现有手势。

#### Scenario: 诊断显示时可正常按住说话

- **WHEN** 诊断面板可见且用户于语音圆上按下
- **THEN** 必须仍能正常开始聆听与结束/取消流程

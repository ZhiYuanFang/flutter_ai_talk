## ADDED Requirements

### Requirement: iOS 系统 STT 使用简体中文 locale

The system SHALL pass an explicit Simplified Chinese locale to `speech_to_text` when using system STT on iOS. 当用户在 iOS 选择「系统识别」并按住说话时，客户端必须在调用 `speech_to_text.listen()` 时传入简体中文 `localeId`（与 App UI `zh_CN` 对齐），**不得**依赖设备 `Locale.current` 作为唯一语言来源。

#### Scenario: 系统语言为英文时仍识别中文

- **WHEN** 用户在 iOS 上将系统首选语言设为英文，且在设置中心选择「系统识别」后按住说话并说中文
- **THEN** 系统 STT 必须使用简体中文 locale 启动识别，转写结果应为中文（在设备已安装中文听写语言包的前提下）

#### Scenario: prepare 阶段解析可用中文 locale

- **WHEN** `SystemSttHomeSpeechRecognizer.prepare()` 成功完成
- **THEN** 实现必须从 `speech_to_text.locales()` 中按约定优先级（`zh_CN`/`zh-CN` → `cmn-Hans-CN` → 其它 `zh`/`cmn-Hans` 前缀）解析并缓存首选 `localeId`，供后续 `listen()` 使用

#### Scenario: 设备无中文听写包时不崩溃

- **WHEN** 设备未安装中文听写语言包导致系统 STT 无法启动或识别失败
- **THEN** 应用不得崩溃；用户必须仍可改用文字输入或「云端识别」（若可用），行为符合既有「语音不可用时不阻塞非语音功能」要求

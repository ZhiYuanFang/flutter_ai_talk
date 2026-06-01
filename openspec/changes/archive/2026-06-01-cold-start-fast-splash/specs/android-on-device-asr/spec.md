## REMOVED Requirements

### Requirement: Android 使用内置 Vosk 模型进行离线转写

**Reason**: 冷启动与安装包体积优化；产品默认云端 ASR，端侧 Vosk 由 `speech-engine-without-vosk` 能力整体移除。

**Migration**: Android 用户使用「云端识别」或「系统识别」；无网时依赖文字输入或系统 STT（若可用）。旧 `speech_engine=vosk` 自动迁移为 `cloudAsr`。

### Requirement: 模型随 APK 内置并在本地解压复用

**Reason**: 随 Vosk 功能移除，不再内置模型。

**Migration**: 同上。

### Requirement: 音频格式与识别输出

**Reason**: 原需求绑定 Vosk PCM 管线；云端/系统 STT 仍遵循各自实现，不再以 Vosk 为基准单独成条。

**Migration**: 按住说话 partial/final 行为由 `home-input-history-sse` 与现有 cloud/system recognizer 覆盖。

### Requirement: 识别失败时的回退

**Reason**: 回退目标从 Vosk 错误态改为 cloud/system/文字输入，由 `speech-engine-without-vosk` 统一描述。

**Migration**: 保持「语音失败可文字输入」产品规则。

### Requirement: iOS 可选 Vosk 与 Android 固定 Vosk

**Reason**: 双端均不再提供 Vosk 选项。

**Migration**: iOS/Android 设置页引擎列表一致为云端 + 系统。

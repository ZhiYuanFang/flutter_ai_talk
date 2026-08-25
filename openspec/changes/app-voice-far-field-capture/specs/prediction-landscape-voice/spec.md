## ADDED Requirements

### Requirement: 横屏语音 MUST 在平放远场验收集上可识别小声

On **both Android and iOS**, when the device is placed **flat with the screen facing up**, the smart prediction page is in **landscape** and **foreground**, and the user speaks at approximately **2 meters** at **normal quiet volume** after wake, the client MUST achieve reliable ASR for a defined utterance set. Success MUST mean at least **8 of 10** fixed short Chinese test utterances produce usable `asr_partial` and semantically acceptable `asr_final` (or equivalent dialogue outcome) on each platform using representative devices. Wake-word detection at the same fixture MUST use the shared PCM capture configuration. 在 **Android 与 iOS** 上，当设备 **平放且屏幕朝上**、智能预测页 **横屏且前台**、用户唤醒后于约 **2 米**以**正常小声**说话时，客户端 MUST 在定义的 utterance 集上可靠完成 ASR。成功 MUST 定义为：各平台代表机型上，固定 10 句中文短句中至少 **8 句**产生可用 `asr_partial` 与语义可接受的 `asr_final`（或等价对话结果）。同一场景下的唤醒词检测 MUST 使用共享 PCM 采集配置。

#### Scenario: Android 平放 2m 小声对话

- **WHEN** Android 代表机型平放屏朝上、预测横屏前台、用户约 2m 以正常小声说出测试句之一
- **THEN** 客户端 MUST 在 ≥8/10 句上产生可接受的 ASR 结果
- **AND** MUST NOT 因 5s 无有效音 idle 在用户尚未完成有效开口前过早退下（在已触发有效音的轮次）

#### Scenario: iOS 平放 2m 小声对话

- **WHEN** iOS 代表机型平放屏朝上、预测横屏前台、用户约 2m 以正常小声说出测试句之一
- **THEN** 客户端 MUST 在 ≥8/10 句上产生可接受的 ASR 结果

#### Scenario: 2m 小声唤醒

- **WHEN** 用户在上述平放 2m 场景以正常小声说出唤醒词「你好，胖宝」
- **THEN** 客户端 MUST 在验收集上达到与对话段一致的唤醒成功率目标（≥8/10）
- **AND** KWS PCM 采集 MUST 与 chat 上送共用 `AppVoiceRecordConfig`

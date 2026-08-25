## 1. 共享 PCM 采集模块

- [x] 1.1 新增 `app/lib/audio/app_voice_record_config.dart`：`sampleRate=16000`、`pcm16kMono`（`autoGain: true`，`noiseSuppress`/`echoCancel: false`，Android `voiceRecognition`）、`effectiveChunkAvgAbs` 初值 130
- [x] 1.2 `VoiceChatWsClient` 改用共享配置与集中 effective 阈值；`_sendPcm` 打 `[LandscapeVoice]` avgAbs 诊断（debug）
- [x] 1.3 `VoiceAsrWsClient` 改用共享 `pcm16kMono`，删除 inline `_recordConfig`
- [x] 1.4 `LandscapeWakeWord` 的 `start`/`resume` 改用共享 `pcm16kMono`，删除两处 inline `RecordConfig`

## 2. Go 服务端 effective 对齐

- [x] 2.1 在 `go_ai_talk`（`voice_ws.go` 或等价）下调流式 effective 能量门，与 Flutter `effectiveChunkAvgAbs` 对齐（建议初值 150 或标定后 ±20）
- [x] 2.2 确认 `/voice/asr/ws` 若共用 effective 逻辑则同步；记录运维可调常量位置

## 3. 文档与约束

- [x] 3.1 `app/README.md` 补充「App 语音 PCM 采集」：`AppVoiceRecordConfig` 消费方列表与系统 STT 例外
- [x] 3.2 确认本变更无新增 debug tag；若新增则三联改 `app_debug_log.dart` / `logcat_api_http.ps1` / README Debug 表

## 4. 真机验收（平放屏朝上 · 2m · 小声）

- [x] 4.1 准备固定 10 句中文短句 + 唤醒词「你好，胖宝」脚本；记录代表 Android / iOS 机型
- [ ] 4.2 Android：平放屏朝上、预测横屏、2m 小声 — 唤醒 ≥8/10、对话 ASR ≥8/10；记录 avgAbs 与未通过句
- [ ] 4.3 iOS：同场景 — 唤醒 ≥8/10、对话 ASR ≥8/10；记录 avgAbs 与未通过句
- [ ] 4.4 若未达标：据 avgAbs 调整 `effectiveChunkAvgAbs` 与 Go effective 后复测（仍不启用 NS、不掐帧）

## 5. 回归

- [ ] 5.1 近场按住说话（首页云端 ASR）回归：采集无异常、转写仍可用
- [ ] 5.2 横屏 idle 5s / `asr_no_result` 续听 / barge-in 路径 smoke（行为不因采集变更破坏）

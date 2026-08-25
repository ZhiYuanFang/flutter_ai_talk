## Why

预测页横屏语音在真实使用场景（手机**平放、屏幕朝上**、用户约 **2m** 距离**小声**说话）下，Android 与 iOS 均难以稳定触发有效音与 ASR 转写；同时 App 内多处 PCM 采集（横屏对话、首页云端 ASR、横屏 KWS）各自 inline 裸 `RecordConfig`，声学行为不一致。需在**不引入客户端掐帧/咳嗽门控**的前提下，统一远场导向采集配置并下调双端有效音门槛，使双端在定义验收集上可识别 2m 小声。

## What Changes

- 新增 **`AppVoiceRecordConfig`**（或等价模块）作为 App 内 **唯一** PCM `RecordConfig` 真相源；凡使用 `record` 包上送 PCM 的路径 **MUST** 引用该配置，**不得**再 inline 分散定义。
- 远场导向采集：**`autoGain: true`**；Android **`voiceRecognition`** 音源；**`noiseSuppress` / `echoCancel` 默认 false**（v1 防糊、保弱音）；仍 **连续送帧**，本变更 **不做** 客户端静音掐帧。
- 下调客户端 **`effectiveChunkAvgAbs`**（初值经真机标定，目标区间约 120–140）并打 `[LandscapeVoice]` avgAbs 诊断日志；横屏 5s idle 逻辑不变，仅门槛与采集变。
- **Go（`go_ai_talk`）**：下调 `/voice/chat/ws`（及若共用则 `/voice/asr/ws`）服务端 **effective** 能量门（原约 avgAbs≈220），与 Flutter 对齐；**不在本变更** 调整 `wsInterruptCommitGap` 数值或做 Go 层频谱降噪。
- **系统识别**（`speech_to_text` / `SystemSttHomeSpeechRecognizer`）**不在** 本变更统一 `RecordConfig` 范围；规格中写清例外。
- 咳嗽误判 / 杂音切断 **后置** 于独立 change；本变更 **Non-Goal**。
- 真机验收：平放屏朝上、2m、正常小声；Android + iOS 各固定句集 **≥8/10** 唤醒 + 对话 ASR 成功率。

## Capabilities

### New Capabilities

- `app-voice-capture`：App 内 PCM 语音采集配置原子化（唯一 `RecordConfig`、有效音能量常量、消费方约束与系统 STT 例外）。

### Modified Capabilities

- `prediction-landscape-voice`：横屏语音在远场验收集上 MUST 可识别 2m 小声；KWS 与 chat 共用采集配置。
- `voice-asr-ws`：首页按住云端 ASR MUST 使用与横屏相同的共享 PCM 采集配置（行为一致，非新协议）。
- `voice-chat-ws`：横屏 chat 上送 MUST 使用共享采集配置；有效音门槛下调后的 idle/续听语义不变。

## Impact

- **Flutter**：新增 `app/lib/audio/app_voice_record_config.dart`（或等价）；修改 `voice_chat_ws_client.dart`、`voice_asr_ws_client.dart`、`landscape_wake_word.dart`；可选 `app/README.md` Debug 表若新增日志字段。
- **Go（兄弟仓 `go_ai_talk`）**：`voice_ws.go`（或等价）effective 门槛常量/配置；须与 Flutter 同批或先部署联调。
- **无** WebSocket 协议帧变更；**无** 新建 `**/test/**`。
- **风险**：更强 AGC + 更低门槛可能暂时增加环境噪声误触 effective（咳嗽 change 后置接受）。

## Context

预测横屏语音真实场景为手机**平放、屏幕朝上**，用户约 **2m** 以**正常小声**对话。当前 `VoiceChatWsClient`、`VoiceAsrWsClient`、`LandscapeWakeWord` 各自 inline 裸 `RecordConfig`（PCM16 / 16k / mono，AGC/NS/AEC 全关）；客户端有效音门槛 `avgAbs >= 200`，与服务端 effective≈220 对齐。远场小声能量不足，导致 5s idle 退下或 ASR 不建连。Go `/voice/chat/ws` 对 PCM 做能量门控与静音计时，**不做** Go 层频谱降噪；百度 STT 消费已上送 PCM。

约束：`/voice/chat/ws` 与 `/voice/asr/ws` 为 WS 例外通道；日志走 `AppDebugLog.landscapeVoice`；不新建 `**/test/**`。系统 STT（`speech_to_text`）不走 `record` 包，本变更不统一其采集链路。

## Goals / Non-Goals

**Goals:**

- 提供 **唯一** App 级 PCM `RecordConfig`（`AppVoiceRecordConfig`），供 chat WS、ASR WS、横屏 KWS **共用**。
- 远场导向采集：`autoGain: true`；Android `voiceRecognition`；v1 **关闭** `noiseSuppress` 与听音段 `echoCancel`；**连续送帧**，不掐帧。
- 下调客户端 `effectiveChunkAvgAbs`（初值 130，真机标定可调）并打 avgAbs 诊断；Go effective 门槛同步下调。
- 验收集：平放屏朝上、2m、正常小声；Android + iOS **≥8/10** 唤醒 + 对话 ASR 成功率（固定句集）。

**Non-Goals:**

- 客户端静音掐帧、咳嗽/杂音门控（后置 change）。
- 本变更调整 `wsInterruptCommitGap` / `wsInitialNoASRGap` 数值。
- 统一系统 STT 采集配置。
- v1 启用 `noiseSuppress`（易糊、削弱远场弱音）。
- 新建自动化测试文件。

## Decisions

### D1：单一模块 `AppVoiceRecordConfig`

**决策**：新增 `app/lib/audio/app_voice_record_config.dart`，导出 `pcm16kMono` 与 `effectiveChunkAvgAbs`（及 `sampleRate` 常量）。

**理由**：采集原子化；KWS ↔ chat 换麦时增益一致；首页云端 ASR 与横屏行为对齐。

**备选**：仅改 `VoiceChatWsClient` — 否决，违反产品「全 App 语音输入同一采集」要求。

**消费方 MUST 替换 inline `RecordConfig`：**

- `voice_chat_ws_client.dart`
- `voice_asr_ws_client.dart`
- `landscape_wake_word.dart`（`start` 与 `resume` 两处）

### D2：远场采集参数（Platform matrix）

| 字段 | Android | iOS | 共享 |
|------|---------|-----|------|
| `autoGain` | true | true | ✓ |
| `noiseSuppress` | false | false | ✓ |
| `echoCancel` | false（听音段） | false | ✓ |
| `androidConfig.audioSource` | `voiceRecognition` | — | Android only |
| `iosConfig` | 默认 | 默认 | iOS 无 voiceRecognition 对等项 |

**理由**：AGC 抬远场电平；NS 易与云端识别叠层且可能发闷；AEC 留给 TTS/barge-in 既有策略。

### D3：有效音门槛与标定

**决策**：`effectiveChunkAvgAbs` 初值 **130**（低于现 200）；实现后在**平放屏朝上 2m 小声**下读 `[LandscapeVoice]` avgAbs 日志迭代；Go effective 从 ~220 降至与客户端对齐（建议 **150** 或标定后 ±20）。

**理由**：仅降采集不降门槛无法过 idle；门槛过低增加噪声误触（咳嗽 change 后置接受）。

**备选**：等 `asr_partial` 才取消 5s idle — 否决（过晚，idle change 已拍板）。

### D4：不掐帧

**决策**：`_sendPcm` 仍 `sink.add` 全部 PCM 块；不在本变更做能量门控不上送。

**理由**：远场优先；掐帧与服务端 VAD 竞态，且会伤害 2m 弱音。

### D5：系统 STT 例外

**决策**：`SystemSttHomeSpeechRecognizer` 不在范围；规格 REQUIREMENT 明确例外。用户选「系统识别」时行为不变。

### D6：跨仓 Go

**决策**：OpenSpec tasks 含 `go_ai_talk` `voice_ws.go`（或等价）effective 常量下调；Flutter 与 Go **同批或先 Go** 联调。

**备选**：仅 Flutter — 否决，服务端 ~220 仍挡 ASR 建连。

### D7：验收姿势写死

设备平放于平面、**屏幕朝上**、预测横屏前台、口部与设备约 2m、**正常小声**（非耳语）。代表机型各 1 台 Android + 1 台 iPhone；固定 10 句中文短句；唤醒词 + 对话各计成功率。

## Risks / Trade-offs

- **[Risk] 更强 AGC + 低门槛 → 咳嗽/环境声误触 effective** → 本变更接受；后置咳嗽 change。
- **[Risk] 平放屏朝上麦向差，代表机仍不达标** → avgAbs 标定 + 产品 UX 提示；spec 绑定验收集而非「任意机型 100%」。
- **[Risk] iOS `noiseSuppress` 字段未独立映射** → v1 保持 false；不依赖 iOS NS。
- **[Risk] 仅部署 Flutter 未部署 Go** → 文档与 tasks 要求双端同批验证。
- **[Trade-off] 首页云端 ASR 也开 AGC** → 近场可能略抬底噪；与原子化一致。

## Migration Plan

1. 合入 `AppVoiceRecordConfig` 并替换三处消费方。
2. 部署 Go effective 下调（与 Flutter 对齐）。
3. 真机：Android/iOS 平放 2m 矩阵（唤醒 + 对话）。
4. 回滚：恢复 inline 裸配置与原门槛常量；Go 恢复原 effective。

## Open Questions

（无）平放屏朝上、双端、原子化采集、不掐帧、NS 默认关、Go 对齐已确认。

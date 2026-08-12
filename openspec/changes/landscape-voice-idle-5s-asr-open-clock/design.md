## Context

横屏语音：`beginListen` 上送 PCM → Go `/voice/chat/ws` 仅在有效音后建百度流式 ASR；`wsInitialNoASRGap` 当前相对会话 `start` 的 `streamStartAt` 计时。安静超过该阈值后再出声会立刻 `noFirstSTTTimeout` → 空 commit → `asr_no_result`；Flutter 现将其当整轮退下。安静时 ASR 未建连则服务端超时逻辑不跑。产品拍板：Go 做 G1；客户端开听后 5 秒无有效音退下；会话中空片段续听。

约束：鉴权业务 WS 惯例不适用于本语音通道（既有例外）；客户端日志走 `AppDebugLog.landscapeVoice` / `landscapeKws`；不新建 `**/test/**`。

## Goals / Non-Goals

**Goals:**

- G1：ASR 建连（或首个有效音触发建连成功）时重置首字等待锚点。
- 开听成功后 5s 无有效音 → 「我先退下了」路径。
- 会话中 `asr_no_result` 续听，与无声终局分离。
- 修复退下音 `playAssetWav` 超时回调类型。
- 弹幕不再按「文本静止 3s」清空；与音频绑定：TTS/本地提示音播完再清（无播音则 TurnEnded/结束路径清）。

**Non-Goals:**

- 不调整 Go 的 `wsInterruptCommitGap` / `wsInitialNoASRGap` 数值（运维可另调）。
- 不改唤醒词模型 / KWS CDN。
- 不把「有效音」改为必须等 `asr_partial` 才取消 5s。
- 不在本变更改硬件固件。

## Decisions

1. **G1 锚点**  
   在 `openStreamASR` 成功赋值 `streamASR` 后将用于 `wsInitialNoASRGap` 的时刻重置为 `time.Now()`（推荐重置 `streamStartAt`，或引入 `asrWaitStartAt` 专用于首字判定并在判超时处改用该变量）。  
   **备选**：仅在 `effectiveChunk` 首次为真时重置——与建连时机几乎等价；建连失败重试时亦应避免沿用过期锚点。  
   **理由**：超时语义是「ASR 已在听却无字」，不是「会话 start 后无字」。

2. **5s 无声：锚点 = `beginListen` 成功**  
   不含「我在」播报时长。有有效音则取消 Timer；从未有有效音则超时退下。  
   **备选**：从唤醒词起算——否决，提示音会吞窗口。

3. **有效音：本地 PCM 能量**  
   在 `VoiceChatWsClient` 上送路径用已有 `pcm16ProcessChunk` / 分片 avgAbs（阈值对齐或略低于服务端 effective，避免过灵敏），对外暴露「本轮是否已有有效音」或回调/标志供 provider 取消 5s。  
   **备选**：等 `asr_partial`——否决为主路径（过晚且依赖建连）。

4. **`asr_no_result` 策略**  
   - 本轮尚无有效音且仍在 5s 窗内：可忽略并续听（与现有 grace 合并或替换）。  
   - 本轮已有有效音：MUST 停麦后再 `beginListen`（或确保麦仍开且服务端已 reset），**不得**走「我先退下了」。  
   - 仅 5s 无声超时（及显式 `exit` 等）走退下 UX。  
   **备选**：继续凡 `asr_no_result` 即退下——否决，与 Go「继续接收」冲突。

5. **退出 single-flight**  
   `_exitWithWoXianTuiXia` 必须防重入，避免多次 `asr_no_result`/定时器并发。

6. **跨仓落地**  
   OpenSpec 任务明确改 `go_ai_talk` 的 `voice_ws.go`；Flutter 与 Go 宜同批验证。

7. **弹幕清空跟音频**  
   废除答语阶段「文本静止 3s 清空」。`_setSubtitle` 只更新文案；本地 `playAssetWav` 与服务端 TTS（`TurnEnded` 在播完后发出）结束后 `_clearSubtitle`。无播音的结束路径同样清。ASR/thinking 文案由后续答语覆盖或播完清。

## Risks / Trade-offs

- **[Risk] 环境噪声取消 5s** → 能量阈值略保守；真机调。  
- **[Risk] 仅部署 Flutter 未部署 G1** → 「有声秒退」可能仍在；文档要求双端。  
- **[Risk] 续听抢麦失败** → 日志 + 可降级退下；与既有 restoreWake 衔接。  
- **[Trade-off] 重置 `streamStartAt` 可能影响其它依赖该字段的日志/自动 commit** → 实现前扫引用；若冲突则用独立 `asrWaitStartAt`。  
- **[Trade-off] 「我在」播完即清字幕** → 接受；左下状态仍提示请说话。

## Migration Plan

1. 先合/部署 Go G1，再发 Flutter；或同批发。  
2. 真机：安静 >5s 退下；开口后可说话不秒退；中间空片段不退下；答语弹幕播音期间可见、播完消失。  
3. 回滚：恢复旧时钟与「凡 no_result 退下」；去掉 5s Timer；可恢复 3s 弹幕清。

## Open Questions

（无）G1、5s、本地能量、空片段续听、弹幕跟播完清已确认。

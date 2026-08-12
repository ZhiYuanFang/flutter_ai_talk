## Why

横屏语音出现「不说话可一直听、一有声音就立刻退下」：服务端仅在有效音后才建流式 ASR，但「首字超时」仍用会话 `start` 时刻，安静超过阈值后再出声会立刻空 `commit` → `asr_no_result`；同时安静时 ASR 未建连导致服务端超时根本不跑，用户可无限干听。需在 Go 重置首字时钟（G1），并在客户端用「开听后 5 秒无有效音」做真正的无声退出。

## What Changes

- **Go（兄弟仓 `go_ai_talk`）G1**：首个有效音建连流式 ASR 成功时，重置「等待首个 STT」计时锚点（不得继续沿用过期的 `start` 时刻做 `wsInitialNoASRGap` 判定）。
- **Flutter**：`beginListen` 成功后启动 **5 秒**无有效音定时器；超时走「我先退下了」+ 本地退下音 + 回待唤醒；本轮一旦检出有效音则取消该定时器。
- **Flutter**：会话进行中的空片段 `asr_no_result`（服务端语义为继续接收）MUST 续听/重新开听，不得当作整轮终局退下；与 5 秒无声终局区分。
- **Flutter**：修复 `playAssetWav` 的 `onTimeout` 类型错误，保证退下音可播。
- 与既有 `landscape-voice-no-result-subtitle`（退下文案/弹幕/再次唤醒）衔接，不撤销其退下 UX；修正「凡 `asr_no_result` 即退下」的过宽策略。

## Capabilities

### New Capabilities

- `landscape-voice-listen-idle`：开听后无有效音超时退下；会话中空 `asr_no_result` 续听策略。
- `voice-chat-asr-open-clock`：`/voice/chat/ws` 流式模式下首字等待时钟与 ASR 建连对齐（G1，实现落在 `go_ai_talk`）。

### Modified Capabilities

- （无）v2.1.0 合并基线尚未收录横屏语音 listen 生命周期；本变更以新增 capability 描述行为。与进行中的 `landscape-voice-no-result-subtitle`（`landscape-voice-turn-ux`）互补：本变更收窄 `asr_no_result` 终局条件并增加无声超时。

## Impact

- `D:/work/go_ai_talk/internal/controller/voice_ws.go`（及必要日志）：G1 时钟重置。
- `app/lib/providers/landscape_voice_provider.dart`：5s 无声定时、续听策略、与 `_exitWithWoXianTuiXia` 衔接。
- `app/lib/voice/voice_chat_ws_client.dart`：有效音信号（PCM 能量）、`asr_no_result` 事件语义、`playAssetWav` 超时修复。
- 联调依赖 Go 与 Flutter 同步部署；仅改一端无法完整消除「有声秒退」或「无限干听」。

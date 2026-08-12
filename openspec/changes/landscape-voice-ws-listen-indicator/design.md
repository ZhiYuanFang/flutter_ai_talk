## Context

横屏语音：`LandscapeVoiceController` 在 activate 时异步 `chat.connect()`，唤醒后 `_onWake` 顺序为 pause KWS → 播「我在」→ `beginListen()`。卡死复现为左下角长期停在「我在听…」，说明卡在该链路中段 `await`（尤其双 `AudioRecorder` 切换时的 `pause`/`startStream` 无超时）。`VoiceChatWsClient` 已有 `isReady`/`readyStream`/`isListening`，但未进入 UI state。产品已拍板：待唤醒且 WS 已连 → 绿点要亮；绿点 + 话筒高亮 = 已连接且本轮在听。

## Goals / Non-Goals

**Goals:**

- Chip 三态：红（未连）/ 绿弱或绿点+不高亮（已连待唤醒）/ 绿点+话筒高亮（已连且本轮上送）。
- 唤醒开听启动可完成或可失败恢复，不得永久停在「我在听…」。
- Debug 可观测各启动步骤。

**Non-Goals:**

- 不改 chat WS 帧协议、不改 JWT 例外策略。
- 不合并双 Recorder 为单一实例（可后续）；本期以超时+短延迟+日志止血。
- 不做服务端 VAD/`asr_no_result` 策略变更。
- 不改 KWS 模型 CDN（已另 change）。

## Decisions

1. **指示灯语义（写死）**  
   - `chatConnected == false` → 红点；话筒不高亮。  
   - `chatConnected && !chatListening` → 绿点亮；话筒不高亮（含待唤醒、播「我在」、启动中）。  
   - `chatConnected && chatListening` → 绿点 + 话筒高亮。  
   `chatListening` MUST 对齐 `VoiceChatWsClient.isListening`（`beginListen` 成功置位），MUST NOT 仅用 `awakened`（避免「我在听…」卡死时误高亮）。

2. **状态来源**  
   `LandscapeVoiceUiState` 增加 `chatConnected` / `chatListening`；activate 时订阅 `readyStream`，并在 `beginListen`/`_stopMicOnly`/`_finishTurn` 路径同步 `chatListening`。断线时红点立即反映。

3. **开听启动防挂死**  
   - `_onWake` 分阶段 `onStatus`：暂停麦 / 播报 / 连接会话 / 开麦。  
   - `pause`、`startStream`（及可选 pause 后 100–300ms 再开流）加超时（建议 3–5s）；超时视为失败。  
   - 失败：日志 + 短因、`_turnBusy=false`、`resume` KWS、`awakened=false`。  
   - 任意提前 `return`（含 `!_active`）MUST 清 `_turnBusy`。

4. **Debug tag `[LandscapeVoice]`**  
   三联改；记录 connect 结果、wake 各步、startStream/err、ready 变化。禁止裸 `debugPrint`。

## Risks / Trade-offs

- **[Risk] 超时误杀慢机开麦** → 阈值 3–5s 可调；失败可点按重试。  
- **[Risk] 仍双 Recorder 竞态** → 超时+短延迟缓解；长期可单 Recorder。  
- **[Trade-off] 启动中也是绿点不高亮** → 与「待唤醒」同态；靠文案区分「我在听…」/「请说话…」。

## Migration Plan

1. 合入 UI 指示 + state 订阅。  
2. 合入开听超时与日志。  
3. 真机：绿点待唤醒 → 唤醒后应进「请说话…」且话筒高亮；人为断网红点。  
4. 回滚：去掉点与超时，恢复旧 chip。

## Open Questions

（无）三态与「待唤醒绿点要亮」已确认。

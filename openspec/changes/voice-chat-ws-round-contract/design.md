## Context

Go `/voice/chat/ws` 在流式成功答完后设置 `waitEndAfterCommit`：未收到客户端 `end` 前丢弃 PCM；收到 `end` 后须再 `start` 才能开下一音频窗。意图层另下发 `finish_talk`（及 `exit`）表达「是否还要用户接话」。Flutter 现状：`ensureSessionStarted` 在 `_sessionStarted==true` 时直接返回；`_finishTurn` 不发 `end`；`TurnEnded` / `VoiceChatAnswer` 不带 `finish_talk`；唤醒至开听期间 `_turnBusy` 过宽导致芯片点击无效——多轮假死与「服务端控制续聊」产品意图均未落地。

约束：语音 chat WS 为无鉴权例外（与 ASR 同类）；日志走 `AppDebugLog.landscapeVoice`；本仓不改 Go 门闩；不新建 `**/test/**`。

## Goals / Non-Goals

**Goals:**

- 客户端对齐传输层：凡需再上送用户语音前，若服务端可能处于 `waitEndAfterCommit`，先 `end` 再 `start`。
- 客户端对齐意图层：解析并尊重 `finish_talk` / `exit`，决定续听或回唤醒。
- 客户端主动结束本段（含 5s idle 退下）MUST 发 `end`；续听开听 MUST 重武装 5s idle。
- 解除「请说话」假死时话筒不可点、忙标记不释放的问题。

**Non-Goals:**

- 不修改 Go `waitEndAfterCommit` / `finish_talk` 生成逻辑（G1 等属其它 change）。
- 不改思考分段、`asr_no_result` 退下文案、idle **时长/退下音频资产**（仍 5s +「我先退下了」）；本变更只保证 idle/回唤醒路径补发 `end`，以及续听路径复用同一 idle 武装。
- 不做 `type=text` 上行；不引入 `ResilientWebSocketClient`。

## Decisions

1. **双层状态机显式化**  
   - 传输：`needsRoundRestart`（或等价）在成功答完 / `audio_end` 后置位；下次 `beginListen` 或续听前执行 `end`→`start`。  
   - 意图：`finishTalk` 从 `answer`/`audio_end` 解析，缺省按「结束本段对话回唤醒」保守处理（若帧缺失），避免无限假听。  
   - 备选：仅依赖断开重连清门闩 → 否决（延迟高、违背现网硬件契约）。

2. **`finish_talk=false` → 同连接续听**  
   TTS/`TurnEnded(ok)` 后：停麦清理 → `end`→`start` → `beginListen` → 文案「请说话…」，**不** `resume` KWS；并 **重置 `_heardEffectiveSpeech` + `_armIdleNoSpeechTimer()`**，避免连续对话无限干听。  
   `finish_talk=true` 或 `exit`：`end`（可不清连）→ `_finishTurn` 回唤醒。  
   备选：一律回唤醒再靠用户再说唤醒词 → 否决（违背服务端 NeedUserReply/澄清续聊）。

3. **`TurnEnded` 携带 finishTalk**  
   在 `VoiceChatTurnEnded`（或并列事件）带上 `finishTalk`/`exit`，由 provider 分支；避免 provider 再解析原始 JSON。  
   `asr_no_result` 软续听路径：若此前已进入 waitEnd 态，续听前同样 `end`→`start`。

4. **客户端主动结束本段 MUST `end`（含 idle）**  
   今日 `_exitWithWoXianTuiXia` / `_finishTurn` 只 `ensureMicStopped`，不调 `endSession()`。改为：凡结束对话段回唤醒的路径（5s idle 退下、`finish_talk=true`、`exit`、芯片强制退出本段）在停麦后 MUST 调用 `endSession()`/`sendEnd()`（连接仍开时），再 resume KWS。  
   备选：仅断 socket → 否决（重连贵，且与硬件 end/start 契约不符）。

5. **忙标记与芯片**  
   `beginListen` 成功武装后清除或收窄 `_turnBusy`；`onListenChipTap` 在「请说话」且无进展时可强制 `end`→复位→重新开听或回唤醒，防止假死。  
   备选：仅超时自动复位 → 可作为补充，但不替代显式芯片恢复。

6. **API 形态**  
   在 `VoiceChatWsClient` 增加 `restartAudioRound()`（`end`+`start`）与可复用的 `endSession()`/`sendEnd()`；`beginListen` 在需要时内部调用 restart；结束本段统一走 `end`。

## Risks / Trade-offs

- [误判缺省 `finish_talk`] → 帧缺失时保守回唤醒；Debug 日志打印解析值。  
- [end/start 竞态与 in-flight TTS] → 仅在麦已停且 TTS 播完的 `TurnEnded` / 明确续听入口调用；single-flight 包住 `restartAudioRound`。  
- [软 `asr_no_result` 与 waitEnd 叠加] → 软续听统一走同一 `beginListen` 前置 restart。  
- [与并行 idle/no-result change 冲突] → 不改 5s/退下资产；仅补 `end` 与续听重武装 idle。  
- [idle 发 end 与未 start 竞态] → `endSession` 在未 start 时 no-op 或吞错；Debug 记 `idle_exit end`。

## Migration Plan

1. 先落地 client 解析 + `restartAudioRound` / 统一 `end`，再改 landscape 分支与 idle 退下。  
2. 真机：唤醒→说话→答完→`finish_talk=false` 应直接「请说话」且能再说话；续听后 5s 无声退下且日志/抓包可见 `end`；`true` 回唤醒亦见 `end`；故意卡死后点话筒可恢复。  
3. 回滚：恢复「一律 `_finishTurn` 且不 end」即可，无数据迁移。

## Open Questions

- `answer` 与 `audio_end` 的 `finish_talk` 不一致时以谁为准？（建议：**以 `audio_end` 为准**，因其更接近轮次结束；`answer` 可预缓存。）  
- 陪伴页 `/companion` 若共用 `VoiceChatWsClient` 是否同步分支？（建议：client 层通用；陪伴 UI 若另有编排则同 PR 最小对齐或单列 follow-up。）

## Context

`_afterServerCommit` 在有效音后 `unawaited(_armBargeInWake())`，与 `audio_end`→TTS 重叠；KWS `AudioRecord` 启动后系统 pause TTS。产品决策：Thinking 可打断，Speaking 禁止。

## Goals / Non-Goals

**Goals:**

- Thinking：保留 barge-in arm。
- Speaking 开始前：必 pause KWS + 清 `_bargeInArmed`（或等价门闩）。
- Speaking 期间：唤醒词不得走 barge-in；麦不归 KWS。
- 日志标明 pause/disarm 原因。

**Non-Goals:**

- 不实现「播中唤醒词打断」与音频焦点 spike。
- 不要求播中芯片打断 TTS（禁止打断含播中）。
- 不改 `finish_talk` / `TurnEnded` / tts-turn-seal 超时公式。
- 不重写整套 VoicePhase 框架（本变更只收窄时序）。

## Decisions

1. **钩子：开播前 disarm**  
   在 `VoiceChatWsClient._onAudioEnd` 取到 PCM、调用 `_playPcm16Le` **之前**，经回调通知编排层（如 `onBeforeTtsPlay`），由 provider `_disarmBargeInForTts()`：`_wake?.pause()` + `_bargeInArmed=false`。  
   **替代**：仅在 provider 猜「answer 后 delay」——不可靠；拒绝。  
   **替代**：client 内直接持有 wake——破坏分层；拒绝。

2. **Thinking arm 时机不变**  
   仍在 `_afterServerCommit` 且 `_heardEffectiveSpeech` 时 arm。空结果续听不开 barge-in（现逻辑保留）。

3. **Speaking 门闩**  
   `_onWakeDetection`：若「TTS 播放中」或「已为 tts  disarm 且尚未 TurnEnded」则忽略 barge-in（即使 `_bargeInArmed` 残留）。可用 `chat` 暴露 `isTtsPlaying` 或 provider 本地 `_ttsPlaybackActive` 在 beforeTts/TurnEnded 翻转。

4. **TurnEnded 后**  
   `continueListen` 已 `disarm`；`_finishTurn` 已 disarm + restore wake。无需在 Speaking 结束后再 arm barge-in。

5. **芯片**  
   Speaking 时现有 forceReset 认「思考中/请说话」；播中 caption 多为「思考中…」可能仍能点——实现时：若 `_ttsPlaybackActive`，芯片 MUST NOT 走 barge-in/stopTts 打断播（可 no-op 或仅提示），与「播放禁止打断」一致。优先简单：播中 forceReset 跳过停 TTS。

## Risks / Trade-offs

- [Risk] `onBeforeTtsPlay` 与 play 之间仍有极短窗 → Mitigation：先 await disarm 再 play。  
- [Risk] 用户想播中喊停 → 产品已放弃；播完再说。  
- [Trade-off] 不引入完整状态机 — 降低套娃，后续若再扩展再抽。

## Migration Plan

纯客户端。回滚：去掉 beforeTts disarm 与播中门闩。

## Open Questions

（无）

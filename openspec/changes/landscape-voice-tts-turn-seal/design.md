## Context

`VoiceChatWsClient._onAudioEnd` 在累计 PCM 后 `await _playPcm16Le`，仅在 `onPlayerComplete`（现 timeout **2 分钟**）或异常后才 `_emit(VoiceChatTurnEnded)`。编排层靠该事件清字幕并按 `finish_talk` 续听/回唤醒。真机偶发：声已停但 complete 不来 → 字幕假死、服务端可能已 `waitEndAfterCommit`。另：`audio_chunk`/`audio_end` 均 `unawaited`，存在半包开播。

约束：不改 Go；`finish_talk` / barge-in discard 语义保持；日志 `AppDebugLog.landscapeVoice`。

## Goals / Non-Goals

**Goals:**

- `audio_end` 非 discard 路径下，短时内必有一次 `TurnEnded`（正常播完或超时/失败）。
- 播放超时与 PCM 时长挂钩，默认数量级为「时长 + 数秒 slack」，上限封顶（建议 ≤30s slack 外再 cap）。
- chunk 与 `audio_end` 串行，降低半包播。

**Non-Goals:**

- 不改 `finish_talk` 解析与 landscape 续听/回唤醒分支。
- 不把成功 barge-in（`_ttsDiscard`）改成补发 `TurnEnded`。
- 不做「仅 answer、永无 audio_end」看门狗（可另开 change）。
- 不新建测试文件。

## Decisions

1. **时长感知超时**  
   `timeout = max(minFloor, pcmDuration + slack)`，再 `min(..., hardCap)`。  
   - pcmDuration ≈ `bytes/(2*sampleRate)` 秒  
   - slack 建议 3–5s；minFloor 建议 8s；hardCap 建议 45–60s（替换 2min）  
   **替代**：固定 15s — 长答易误切；拒绝为唯一策略。  
   **替代**：保持 2min — 不满足 A 体感；拒绝。

2. **超时仍 seal TurnEnded**  
   timeout/`TimeoutException` 后 stop player，若非 discard，仍 `_emit(TurnEnded(ok: true, finishTalk: …))`（ok 可用 true 表示话轮意图成功收口，或 ok:false+message=`tts_timeout` 由编排清字幕仍走 finishTalk 分支——**建议 ok:true** 以免走错误 caption，因用户已听部分回复）。Debug 打 `tts play timeout seal`。

3. **帧串行队列**  
   `_dispatchJson` 对 `audio_chunk`/`audio_end` 改为 `await` 入队 single-flight链（`_audioPipeline = _audioPipeline.then(...)`），保证 end 时 buffer 含已入队 chunk。thinking/answer 等可仍同步。  
   **替代**：仅 end 前短 delay — 不可靠；拒绝。

4. **discard 不变**  
   `_ttsDiscard` 时跳过 TurnEnded，由 barge-in 编排负责。

5. **编排层**  
   优先零改 provider；若选 `ok:false`+message 需确认不会挡住 `finishTalk` 分支（现网非 asr_no_result 仍清字幕并 finish/continue）——两种均可，实现取 ok:true + 日志更简单。

## Risks / Trade-offs

- [Risk] 极慢设备播完晚于 timeout → 提前 seal 后仍在响 → Mitigation：slack + hardCap；seal 时 stop player。  
- [Risk] 串行队列若 chunk 处理阻塞 end → Mitigation：chunk 仅 decode+append，轻量。  
- [Trade-off] 超时当成功收口可能截断尾音 — 优于假死。

## Migration Plan

纯客户端。回滚：恢复 2min timeout 与 unawaited chunk/end。

## Open Questions

（无）超时公式常量实现时可微调，不阻塞提案。

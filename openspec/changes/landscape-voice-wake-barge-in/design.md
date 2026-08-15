## Context

横屏语音：唤醒后 `pause` KWS，麦克风交给 chat；至 `_finishTurn` 才 `resume`。思考与 TTS 期间再说「你好，胖宝」无效。用户确认：打断范围 = **思考 + TTS**；手段 = **必须再说唤醒词**。

## Goals / Non-Goals

**Goals:**

- 自服务端 `interrupt_commit`（或进入「思考中」且上行已停）起，到本段正常结束前，恢复 KWS 以便 barge-in。
- 唤醒词命中：停 TTS → `endSession` → 再走「我在」+ `beginListen`（不要求先回待唤醒文案再等第二次唤醒）。
- 「我在」与麦权交接期间 `_turnBusy`（或等价）防自唤醒。

**Non-Goals:**

- 不以 chip / 能量 barge-in 为本变更主路径（chip 既有恢复逻辑可保留）。
- 不实现服务端 LLM cancel 新协议（`end` 清会话窗即可）。
- 不要求用户上行聆听阶段并行 KWS（仍独占 chat 麦）。
- 不新建 `**/test/**`。

## Decisions

### D1：还麦锚点 = commit 之后（思考+TTS 同一窗口）

在 `_afterServerCommit`（或等价：上行已停且进入思考/等待答案）调用 `ensureMicStopped` 后短延迟，再 `_armBargeInWake()`：`wake.resume()`（失败可 fallback `start`）。

用户仍在 `请说话…` 上行时：**不**开 barge-in KWS（避免双占麦）。

### D2：命中路径 = barge-in 专用入口

`_onWake` 今日在 `_turnBusy` 时直接 return。改为：

- 若 `_bargeInArmed && awakened`（对话段未结束）：走 `_onBargeInWake()`  
  1. 置忙锁  
  2. `chat.stopTts()`（新增：停 `_ttsPlayer`、清 PCM 缓冲、忽略后续 chunk 至 end）  
  3. `endSession(reason: 'wake_barge_in')`  
  4. 清思考/字幕态  
  5. 再执行与正常唤醒相同的「我在」→ `beginListen`（可抽共用 `_startListenAfterAck`）  
- 待唤醒且非对话中：仍走现有 `_onWake`。

### D3：正常结束与 barge-in 还麦

`_finishTurn`：若 barge-in 已武装，resume 与今日一致（待唤醒）。  
若 barge-in 刚触发正在重开听：由忙锁串行，避免双重 resume。

`finish_talk=false` 续听：开听前再次 `pause` KWS；下次 commit 后再武装 barge-in。

### D4：回声防护（轻量）

- TTS 播放中：可选短冷却（命中后 N ms 内忽略二次检测——本由忙锁覆盖）。  
- 本地「我在」播放期间：忙锁，不处理 detection。  
- 不做完整 AEC；真机若误触再加阈值。

## Risks / Trade-offs

- [TTS 回灌误唤醒] → 忙锁 + 完整唤醒词；必要时提高阈值。  
- [commit 后 resume 与迟到 audio_chunk 竞态] → stopTts 丢弃至 end；endSession 清服务端。  
- [续听 pause/resume 抖动] → 与现有手交接同款 gap/timeout。

## Migration Plan

- 纯客户端。回滚：去掉 commit 后 resume 与 `_onBargeInWake`。

## Open Questions

- （无）范围与手段已确认。

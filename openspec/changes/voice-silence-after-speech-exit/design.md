## Context

`_armIdleNoSpeechTimer` 在 `beginListen` 成功后武装 5 秒。`_onEffectiveSpeechDetected` 第一次有效音就 `_cancelIdleNoSpeechTimer(reason: 'effective')`，到点若已有有效音则 `idle fire skipped hasSpeech` 且不再武装。已有有效音后的 `asr_no_result` 走 soft rearm，续听但不装计时。思考开始在 `_afterServerCommit`，麦克风已停。续听 `finish_talk=false` 会清有效音并重新武装 5 秒，这条保持。

## Goals / Non-Goals

**Goals:**

- 上行聆听中，离最后一块有效音（或开听后尚无有效音）满 5 秒就「我先退下了」。
- 思考窗内不因静音退下。
- 空 `asr_no_result` 仍续听，并重新开始 5 秒静音窗。

**Non-Goals:**

- 改有效音门槛 130 或自动增益。
- 思考中或回复播放中因安静退下。
- 改服务端 VAD / commit 时机。

## Decisions

### D1：有效音重置计时，不永久取消

- **选择**：每块有效音把同一只 5 秒计时重新拨回满；到点仍走 `_exitWithWoXianTuiXia`。开听后完全无声的 5 秒行为不变。
- **理由**：用户要的是说完再安静也退下。永久取消是现在停在「请说话…」的原因。
- **备选否决**：说完后用更长窗口 — 未另定秒数，与现有 5 秒对齐。

### D2：进入思考即取消

- **选择**：`_afterServerCommit` 且本轮将进入思考（已有有效音、等待回复）时取消计时。回复播放期间不武装。再次 `beginListen`（续听或空结果续听）成功后再武装。
- **理由**：思考中麦克风已停，静音不是用户说完不说了。commit 往往紧跟句尾，取消后不会在思考前被 5 秒误退下，除非用户在上行中已经安静满 5 秒。

### D3：空结果续听要重装计时

- **选择**：soft `asr_no_result` 续听成功后调用与开听相同的武装，不再只在计时器为空时才装。
- **理由**：这条路径今天会取消计时并且不重装。

## Risks / Trade-offs

- [句中停顿超过 5 秒会退下] → 与「说完再静音 5 秒」同一窗口；真机若太短再改常量。
- [思考前的短静音] → commit 进入思考即取消；只有上行中已满 5 秒才退下。

## Migration Plan

- 纯客户端。回滚：有效音再次永久取消计时。

## Open Questions

- （无）5 秒、思考中不退下已确认。

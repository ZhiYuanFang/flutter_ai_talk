## ADDED Requirements

### Requirement: 首字等待时钟 MUST 在流式 ASR 建连成功时重置

For `/voice/chat/ws` stream mode, the server-side timer used to decide “no first STT callback since listen/ASR armed” (`wsInitialNoASRGap`) MUST be anchored to stream ASR session open success (or an equivalent first-effective-audio arming instant), and MUST NOT continue using a stale session-`start` timestamp that predates ASR connection when judging that timeout. After resetting, the server MUST still allow the configured gap for the first STT callback before interrupt-committing an empty fragment. 在 `/voice/chat/ws` 流式模式下，用于判定「尚无首个 STT 回调」的超时（`wsInitialNoASRGap`）MUST 以流式 ASR 会话建连成功（或等价的首个有效音武装时刻）为锚点，MUST NOT 在 ASR 尚未建连或刚建连时继续用早于建连的会话 `start` 时刻做该超时判定。重置后，服务端仍 MUST 按配置的间隙等待首个 STT，再对空片段做 interrupt commit。

#### Scenario: 久静后出声不立即空 commit

- **WHEN** 会话 `start` 后长时间无有效音（ASR 未建连），随后出现有效音并成功建立流式 ASR
- **THEN** 服务端 MUST 重置首字等待时钟
- **AND** MUST NOT 在建连当下仅因 `start` 已超过 `wsInitialNoASRGap` 而立即 interrupt 空 commit

#### Scenario: 建连后仍无字才超时

- **WHEN** 流式 ASR 已建连且在重置后的 `wsInitialNoASRGap` 内仍无首个有效 STT 回调
- **THEN** 服务端 MUST 按既有策略 interrupt commit（允许空结果与 `asr_no_result`）
- **AND** 该超时起算 MUST 不早于本次 ASR 建连（或锚点重置）时刻

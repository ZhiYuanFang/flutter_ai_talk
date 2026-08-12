## ADDED Requirements

### Requirement: 开听后无有效音超时 MUST 退下

After landscape voice uplink listening starts successfully, if no effective local speech energy is detected within 5 seconds, the client MUST end the turn with the「我先退下了」UX (status/subtitle and local exit audio) and return to wake-waiting. The 5-second idle timer MUST start at successful `beginListen`, MUST be cancelled when effective speech energy is first detected in that listen arming, and MUST NOT use wake-word detection time as the anchor. 横屏语音上行聆听成功开始后，若 **5 秒内**未检测到本地有效语音能量，客户端 MUST 以「我先退下了」结束本轮（状态/字幕与本地退下音）并回到待唤醒。该 5 秒定时 MUST 以 `beginListen` 成功为起点，本轮首次有效音 MUST 取消定时，MUST NOT 以唤醒词命中时刻为锚点。

#### Scenario: 五秒无声退下

- **WHEN** `beginListen` 成功且连续 5 秒未出现有效本地语音能量
- **THEN** 客户端 MUST 展示并播放「我先退下了」
- **AND** MUST 结束本轮聆听并恢复待唤醒

#### Scenario: 有声音取消无声退出

- **WHEN** 开听后 5 秒内检测到有效本地语音能量
- **THEN** 客户端 MUST 取消无声退出定时器
- **AND** MUST NOT 仅因该 5 秒窗口届满而退下

#### Scenario: 计时锚点在开听成功

- **WHEN** 用户唤醒并播放「我在」后才 `beginListen` 成功
- **THEN** 无声 5 秒 MUST 从开听成功起算，不得从唤醒词命中起算

### Requirement: 会话中空 asr_no_result MUST 续听而非整轮退下

When the chat WS delivers `asr_no_result` after the user has already produced effective speech energy in the current listen arming (mid-utterance empty fragment), the client MUST keep or re-arm uplink listening and MUST NOT treat that event as the primary whole-turn exit path that plays「我先退下了」. Whole-turn exit via「我先退下了」for silence MUST be driven by the 5-second no-energy idle rule (or an explicit server `exit`), not by every `asr_no_result`. 当本轮开听已出现有效语音能量后，若 chat WS 下发表示空片段的 `asr_no_result`，客户端 MUST 保持或重新开听，MUST NOT 将其作为播放「我先退下了」的整轮主退出路径。无声整轮退下 MUST 由 5 秒无有效音规则（或显式服务端 `exit`）驱动，而非每一个 `asr_no_result`。

#### Scenario: 有声后空片段续听

- **WHEN** 本轮已检出有效音且随后收到 `asr_no_result`
- **THEN** 客户端 MUST 重新进入可说话聆听状态（或等价续听）
- **AND** MUST NOT 因此事件播放「我先退下了」作为主路径

#### Scenario: 无声超时与空片段分离

- **WHEN** 开听后始终无有效音直至 5 秒届满
- **THEN** 客户端 MUST 走「我先退下了」终局
- **AND** 该终局 MUST NOT 依赖必须先收到 `asr_no_result`

### Requirement: 弹幕 MUST 在关联音频播完后清空

Landscape voice subtitle toast MUST remain visible while associated prompt/TTS audio is playing, and MUST clear when that playback completes. The client MUST NOT clear answer (or other held) subtitles solely because the subtitle text was unchanged for 3 seconds. If a turn ends without playback, the client MUST clear the subtitle on turn end. 横屏语音字幕弹幕在关联的提示音/TTS 播放期间 MUST 保持可见，并 MUST 在该段播放结束后清空。客户端 MUST NOT 仅因字幕文本静止 3 秒就清空答语（或其它需跟播的）字幕。若本轮无播音即结束，MUST 在结束路径清空字幕。

#### Scenario: 答语播音期间保留

- **WHEN** 已展示应答字幕且服务端 TTS 仍在播放
- **THEN** 字幕 MUST 保持可见
- **AND** MUST NOT 因静止满 3 秒被清空

#### Scenario: 播完清空

- **WHEN** 关联 TTS 或本地提示音播放结束
- **THEN** 客户端 MUST 清空当前弹幕字幕（除非已被更新的新文案取代且仍需跟随后续播音）

#### Scenario: 无播音结束也清

- **WHEN** 本轮以 `TurnEnded` 等结束且无待播音频
- **THEN** 客户端 MUST 清空弹幕字幕

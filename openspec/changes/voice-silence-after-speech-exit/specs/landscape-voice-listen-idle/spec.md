## MODIFIED Requirements

### Requirement: 开听后无有效音超时 MUST 退下

While uplink listening is armed, the client MUST keep a 5-second silence timer. The timer MUST start at successful `beginListen` and MUST reset to 5 seconds on each new effective local speech chunk. It MUST NOT be cancelled for the rest of that listen arming solely because effective speech was detected. If 5 seconds pass with no new effective speech energy, the client MUST end the turn with the「我先退下了」UX and return to wake-waiting, whether or not earlier chunks in that arming were effective. The timer MUST NOT use wake-word detection time as the anchor. When the session enters the thinking window (utterance committed and reply playback has not finished), the client MUST cancel this timer and MUST NOT exit for silence until uplink listening is armed again.

上行聆听武装期间，客户端 MUST 保持 5 秒静音计时。计时 MUST 以 `beginListen` 成功为起点，每块新的有效本地语音能量 MUST 把计时重置为 5 秒，MUST NOT 仅因已检测到有效音就在本轮聆听内永久取消退下。若 5 秒内没有新的有效音，无论本轮先前是否有过有效音，客户端 MUST 以「我先退下了」结束本轮并回到待唤醒。计时 MUST NOT 以唤醒词命中为锚点。进入思考窗（已提交且回复播放尚未结束）时 MUST 取消该计时，并 MUST NOT 因静音退下，直到再次武装上行聆听。

#### Scenario: 五秒无声退下

- **WHEN** `beginListen` 成功且连续 5 秒未出现有效本地语音能量
- **THEN** 客户端 MUST 展示并播放「我先退下了」
- **AND** MUST 结束本轮聆听并恢复待唤醒

#### Scenario: 说完再静音五秒也退下

- **WHEN** 开听后已经检测到有效本地语音能量
- **AND** 其后连续 5 秒没有新的有效音，且仍处于上行聆听而非思考窗
- **THEN** 客户端 MUST 展示并播放「我先退下了」
- **AND** MUST 结束本轮聆听并恢复待唤醒

#### Scenario: 有效音只重置计时

- **WHEN** 开听后 5 秒窗口尚未届满且又检测到一块有效音
- **THEN** 客户端 MUST 把静音计时重置为 5 秒
- **AND** MUST NOT 因此永久取消本轮退下

#### Scenario: 计时锚点在开听成功

- **WHEN** 用户说出「胖宝」后 `beginListen` 成功，且短「叮」与开听并行
- **THEN** 无声 5 秒 MUST 从开听成功起算，不得从唤醒词命中或「叮」播放结束起算

#### Scenario: 思考中不因静音退下

- **WHEN** 用户话语已提交并进入思考窗
- **THEN** 客户端 MUST 取消静音退下计时
- **AND** MUST NOT 因思考期间没有上行语音而播放「我先退下了」

### Requirement: 会话中空 asr_no_result MUST 续听而非整轮退下

When the chat WS delivers `asr_no_result` after the user has already produced effective speech energy in the current listen arming (mid-utterance empty fragment), the client MUST keep or re-arm uplink listening and MUST NOT treat that event as the primary whole-turn exit path that plays「我先退下了」. After that re-listen succeeds, the client MUST arm the same 5-second silence timer again. Whole-turn exit via「我先退下了」for silence MUST be driven by that timer (or an explicit server `exit`), not by every `asr_no_result`. 当本轮开听已出现有效语音能量后，若 chat WS 下发表示空片段的 `asr_no_result`，客户端 MUST 保持或重新开听，MUST NOT 将其作为播放「我先退下了」的整轮主退出路径。续听成功后 MUST 再次武装同一只 5 秒静音计时。无声整轮退下 MUST 由该计时（或显式服务端 `exit`）驱动，而非每一个 `asr_no_result`。

#### Scenario: 有声后空片段续听

- **WHEN** 本轮已检出有效音且随后收到 `asr_no_result`
- **THEN** 客户端 MUST 重新进入可说话聆听状态（或等价续听）
- **AND** MUST NOT 因此事件播放「我先退下了」作为主路径
- **AND** MUST 重新武装 5 秒静音计时

#### Scenario: 无声超时与空片段分离

- **WHEN** 开听后始终无有效音直至 5 秒届满
- **THEN** 客户端 MUST 走「我先退下了」终局
- **AND** 该终局 MUST NOT 依赖必须先收到 `asr_no_result`

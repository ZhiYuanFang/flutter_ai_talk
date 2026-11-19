## ADDED Requirements

### Requirement: Portrait go-record long-press MUST start a no-wake PTT session

On the smart prediction page in **portrait**, when the user long-presses the go-record pill past the long-press threshold and keeps holding, the client MUST start a press-to-talk voice session without on-device wake-word listening. After the hold becomes active, the client MUST play the same local short ding asset used by landscape wake acknowledgement (asynchronously) and MUST begin PCM uplink on `/voice/chat/ws` via `beginListen` (or equivalent). The client MUST NOT require the user to say「胖宝」. The client MUST NOT play the landscape exit asset（`wo_xian_tui_xia_le` or equivalent）for this portrait PTT path.

预测竖屏长按「去记录」超过阈值并按住时，客户端 MUST 启动无唤醒 PTT；MUST 异步播放与横屏唤醒相同的本地叮，并 MUST 经 chat WS `beginListen` 上送 PCM；MUST NOT 要求说「胖宝」；本路径 MUST NOT 播放退场音。

#### Scenario: Long-press starts listen with ding

- **WHEN** 用户在预测竖屏长按「去记录」超过阈值且仍按住
- **THEN** 客户端 MUST 启动无 KWS 的聆听上送
- **AND** MUST 异步播放本地叮
- **AND** MUST NOT 等待唤醒词

#### Scenario: No exit chime on PTT

- **WHEN** 竖屏 PTT 一轮结束或取消
- **THEN** 客户端 MUST NOT 播放横屏退场音 asset

### Requirement: Portrait PTT release MUST coordinate with in-flight startHold

If the user releases (commit or cancel) while `startHold` / `beginListen` is still in flight, the client MUST NOT no-op and leave a later listen orphaned. Cancel release MUST signal abort so in-flight start abandons and stops mic if already opened. Commit release MUST await successful open-mic then send business `commit`. 松手与开麦竞态时：取消 MUST 中止 in-flight；发送 MUST 等开麦成功再 commit。

#### Scenario: Early cancel aborts in-flight open

- **WHEN** 长按已触发 startHold 但 beginListen 尚未完成，用户滑出取消并松手
- **THEN** 客户端 MUST 放弃本轮开听
- **AND** MUST NOT 在放弃后保持开麦上送
- **AND** MUST NOT 发送业务 `commit`

#### Scenario: Early commit waits for open-mic

- **WHEN** 长按已触发 startHold 但 beginListen 尚未完成，用户在 keep 区内松手
- **THEN** 客户端 MUST 等待开麦成功
- **AND** MUST 随后发送业务 `commit`

### Requirement: Portrait prediction surface MUST preconnect chat WS without KWS

While the portrait smart-prediction surface is visible on non-web Android/iOS and the go-record pill is available, the client MUST preconnect `/voice/chat/ws` (socket ready) without starting on-device wake-word listening and without opening the microphone uplink until a hold session starts. Leaving the portrait prediction surface MUST tear down or end the portrait hold preconnect session per existing chat WS lifecycle rules. 竖屏预测表面可见时 MUST 预连 chat WS 且 MUST NOT 启 KWS/开麦；离开表面 MUST 按既有规则拆除预连会话。

#### Scenario: Visible portrait preconnects

- **WHEN** 用户停留在预测竖屏且 pill 可见
- **THEN** 客户端 MUST 建立或复用 `/voice/chat/ws` 连接
- **AND** MUST NOT 因表面可见而启动「胖宝」唤醒监听
- **AND** MUST NOT 因表面可见而 `beginListen`

### Requirement: Finger-up inside keep zone MUST be the sole business commit

While a portrait PTT hold is active, the client MUST treat finger-up inside the keep zone as the sole business utterance commit and MUST call client `commit` (`commitUtterance` or equivalent). Server `interrupt_commit` (or equivalent early commit) that arrives while the finger is still down MUST NOT drive the portrait PTT business completion path; the client MUST wait for finger-up (or cancel). 按住期间服务端抢先 commit MUST NOT 作为业务收口；松手在 keep 区内 MUST 为唯一业务 commit。

#### Scenario: Release commits

- **WHEN** 用户在 keep 区内松手且本轮已开听
- **THEN** 客户端 MUST 发送 `commit`（或等价）
- **AND** MUST 停麦上送

#### Scenario: Server early commit ignored until release

- **WHEN** 按住期间服务端下发 `interrupt_commit`
- **THEN** 客户端 MUST NOT 因此进入竖屏 PTT 的答复完成/续听主路径
- **AND** MUST 仍等待松手或取消

### Requirement: Sliding beyond inflated keep zone MUST cancel on release

The keep zone MUST be the go-record pill bounds inflated by a documented constant of approximately 24–40 logical pixels (default 32). While holding, if the pointer is outside the keep zone the client MUST enter a cancel-armed visual/state. Releasing outside the keep zone MUST cancel the utterance: stop mic, MUST NOT send business `commit`, and MUST discard in-flight reply presentation for that hold. Releasing inside the keep zone MUST commit as above. 滑出 pill 外扩容错区后松手 MUST 取消；keep 区内松手 MUST commit。

#### Scenario: Release outside cancels

- **WHEN** 用户长按开听后将手指移出 keep 区并松手
- **THEN** 客户端 MUST 取消本轮
- **AND** MUST NOT 发送业务 `commit`

#### Scenario: Edge brush does not cancel

- **WHEN** 用户手指仍在 pill 外扩 keep 区内
- **THEN** 客户端 MUST NOT 将状态标为取消武装（仅因擦到 pill 描边）

### Requirement: Portrait PTT MUST use text output modality and subtitle toast

For portrait PTT sessions the client MUST send `outputModality=text` on chat WS `start` (input remains audio/PCM). The client MUST present ASR / thinking / answer via `LandscapeVoiceSubtitleToast` (or the same widget already used in landscape). The client MUST NOT play server TTS audio for portrait PTT replies. When `outputModality=text`, the client MUST seal the turn from `answer` (including `finish_talk` when present) and MUST NOT block forever waiting for `audio_end`. 竖屏 PTT MUST `outputModality=text`、用横屏同款字幕 toast 展示、MUST NOT 播 TTS，并 MUST 以 `answer` 收口。

#### Scenario: Text start and answer seal

- **WHEN** 竖屏 PTT 开始一轮 `start`
- **THEN** `start` MUST 含 `outputModality` 为 `text`
- **AND** 当服务端下发 `answer` 且无后续 `audio_*` 时，客户端 MUST 展示答复文案并完成话轮收口

#### Scenario: Subtitle toast reused

- **WHEN** 竖屏 PTT 收到非空 ASR 或 answer 文案
- **THEN** UI MUST 通过 `LandscapeVoiceSubtitleToast`（或等价同款组件）展示

### Requirement: Orientation change MUST retarget output modality

When the user rotates between portrait and landscape while prediction voice surfaces are involved, the client MUST cancel any in-flight portrait hold and MUST end the current chat audio session window, then rebind for the new orientation: portrait → preconnect without KWS and future `start` with `outputModality=text`; landscape → existing landscape wake session with `outputModality=audio` (or omit defaulting to audio). Subsequent turns MUST use the modality matching the orientation after the switch. 旋转 MUST 撕进行中会话并按新方向切换 text/audio。

#### Scenario: Portrait to landscape switches to audio

- **WHEN** 用户从预测竖屏旋转到横屏
- **THEN** 客户端 MUST 结束竖屏 hold/预连会话窗
- **AND** 随后横屏对话 `start` MUST 为 audio 输出（可播 TTS）

#### Scenario: Landscape to portrait switches to text

- **WHEN** 用户从预测横屏旋转到竖屏
- **THEN** 客户端 MUST 结束横屏唤醒会话窗
- **AND** 随后竖屏 PTT `start` MUST 为 `outputModality=text`

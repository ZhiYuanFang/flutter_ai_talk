## ADDED Requirements

### Requirement: asr_no_result MUST 以「我先退下了」文案与本地音频结束本轮

When the chat WS reports `asr_no_result` (after any client-side listen grace window), the landscape voice UI MUST show the phrase **「我先退下了」** (subtitle and/or status caption) and MUST play a local preset audio for that phrase before returning to wake-waiting. The client MUST NOT use「没听清，再说一次吧」as the primary user-facing copy for this end reason. 在（经过客户端开听宽限后仍）收到 `asr_no_result` 时，横屏语音 UI MUST 展示 **「我先退下了」**，并 MUST 播放对应本地预置音频，然后再回到待唤醒；MUST NOT 以「没听清，再说一次吧」作为该结束原因的主文案。

#### Scenario: 空结果退下

- **WHEN** 本轮上送后服务端下发 `asr_no_result` 且已过开听宽限（若启用）
- **THEN** 用户可见文案 MUST 为「我先退下了」
- **AND** 客户端 MUST 播放本地退下提示音
- **AND** 播完后 MUST 恢复唤醒监听（待唤醒）

### Requirement: 唤醒后开听 MUST 给予用户开口时间

After playing the local「我在」prompt, the client MUST delay briefly before starting uplink listening, and MUST ignore premature `asr_no_result` for a short grace period after listen starts so the user has time to speak. 播放本地「我在」后，客户端 MUST 短暂延迟再开始上送聆听，并 MUST 在开听后的短宽限内忽略过早的 `asr_no_result`，以便用户有时间开口。

#### Scenario: 播完再开麦

- **WHEN** 「我在」本地音播放结束
- **THEN** 客户端 MUST 再等待一短延迟后才 `beginListen`
- **AND** MUST NOT 在播放尚未结束时开始本轮 PCM 上送

#### Scenario: 开听宽限内空结果不退下

- **WHEN** `beginListen` 成功后处于开听宽限窗口内收到 `asr_no_result`
- **THEN** 客户端 MUST NOT 立刻走「我先退下了」结束本轮
- **AND** MUST 继续保持可说话状态直至宽限结束或出现有效 ASR/其它结束事件

### Requirement: 横屏语音字幕弹幕 MUST 随内容布局并自动消失

Landscape voice subtitle toast MUST size to its text (with a max width within screen insets), MUST wrap long text onto multiple lines, and MUST auto-clear when the subtitle text has not changed for 3 seconds. 横屏语音字幕弹幕 MUST 按文本收缩宽度（在屏幕边距内设上限）、超长 MUST 换行，且文本 **3 秒无变更** 时 MUST 自动清空消失。

#### Scenario: 短文本收窄

- **WHEN** 字幕为短句（如「我在」）
- **THEN** 弹幕容器 MUST NOT 无必要拉满整屏宽度（应随内容，受 maxWidth 约束）

#### Scenario: 长文本换行

- **WHEN** 字幕长度超过可用最大宽度
- **THEN** 文本 MUST 自动换行完整展示

#### Scenario: 静默 3 秒消失

- **WHEN** 某字幕文案展示后连续 3 秒没有新的字幕文本变更
- **THEN** 字幕 MUST 自动消失（清空）

#### Scenario: 新文本重置计时

- **WHEN** 字幕在倒计时内被更新为新文本
- **THEN** 自动消失计时 MUST 重新从 3 秒起算

### Requirement: 本轮结束后 MUST 能再次前台唤醒

After a landscape voice turn ends (including the「我先退下了」exit path) while landscape voice remains active, the client MUST restore on-device wake-word listening so the user can wake again without leaving the page. Resume failures MUST be logged and MUST surface a readable status; the client MAY fall back to a full wake engine restart. 在横屏语音仍激活时，一轮对话结束（含「我先退下了」路径）后，客户端 MUST 恢复本地唤醒监听，使用户无需离页即可再次唤醒。resume 失败 MUST 记日志并给出可读状态；MAY fallback 完整重启唤醒引擎。

#### Scenario: 退下后可再唤醒

- **WHEN** `asr_no_result` 退下音播放完成且仍处于预测横屏激活态
- **THEN** 客户端 MUST 恢复 KWS 监听（或等价完整重启成功）
- **AND** 用户 MUST 能再次通过唤醒词或点按进入新一轮

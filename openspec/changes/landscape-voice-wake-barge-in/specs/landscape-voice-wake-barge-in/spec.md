## ADDED Requirements

### Requirement: Landscape voice SHALL allow wake-phrase barge-in during thinking and TTS

当预测横屏语音已处于本段对话、且用户上行聆听已结束并进入思考和/或服务端 TTS 播放阶段时，客户端 MUST 恢复本地唤醒词监听，使用户可通过再说唤醒词 **「你好，胖宝」**（或等价已配置关键词）打断当前 AI 回合。打断手段 MUST 为该唤醒词命中；本变更 MUST NOT 将任意人声能量或监听 chip 作为唯一/主打断手段。用户仍在向 chat 上送本轮语音时，客户端 MUST NOT 为 barge-in 与上行并行抢占同一麦克风路径。

#### Scenario: Wake during thinking interrupts turn

- **WHEN** 横屏对话已进入思考阶段（上行已停），用户再说「你好，胖宝」
- **THEN** 客户端 MUST 结束当前 AI 回合（停止后续 TTS 若已开始或即将开始），并向服务端发送会话 `end`（或等价清窗），然后 MUST 重新播放本地「我在」并武装新一轮上行聆听

#### Scenario: Wake during TTS interrupts playback

- **WHEN** 横屏正在播放本轮服务端 TTS，用户再说「你好，胖宝」
- **THEN** 客户端 MUST 立即停止 TTS 播放与本地缓冲，MUST 发送会话 `end`（或等价），然后 MUST 走「我在」+ 新一轮开听，MUST NOT 等当前播报自然结束

#### Scenario: Uplink listening does not dual-arm KWS

- **WHEN** 横屏正处于「请说话…」且 chat 正在上送用户语音
- **THEN** 客户端 MUST NOT 同时恢复 barge-in KWS 与上行录音双开麦；唤醒打断窗口 MUST 仅在上行结束后的思考/TTS 阶段武装

### Requirement: Barge-in SHALL not self-trigger on local「我在」prompt

在 barge-in 或普通唤醒后播放本地「我在」及麦克风交接期间，客户端 MUST 忽略或门控唤醒检测，避免本机扬声器导致自唤醒死循环。

#### Scenario: Local ack does not re-enter barge-in

- **WHEN** 客户端因唤醒或 barge-in 正在播放本地「我在」或正在 pause/开麦交接
- **THEN** 同一时段内的唤醒检测 MUST NOT 再次触发完整 barge-in/唤醒启动链

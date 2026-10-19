## MODIFIED Requirements

### Requirement: 横屏 MUST 按 finish_talk 决定续听或回唤醒

After a successful landscape voice answer/TTS turn, the controller MUST branch on server `finish_talk` (and `exit`): when `finish_talk` is false, it MUST keep the chat session and re-arm uplink listening, showing 「请说话…」 as a subtitle rather than as the ball or chip caption, without requiring a new wake phrase; when `finish_talk` is true or `exit` applies (or finish_talk defaults to end-segment), it MUST return to wake-word waiting and show a wake hint that includes 「胖宝」 on the ball or chip. 预测横屏在成功应答/TTS 话轮结束后，控制器 MUST 按服务端 `finish_talk`（及 `exit`）分支：`finish_talk=false` 时 MUST 保持 chat 会话并重新武装上行聆听，且 MUST 以字幕展示「请说话…」，MUST NOT 把该句写在球或芯片文案上，也 MUST NOT 要求再次唤醒词；`finish_talk=true`、适用 `exit`、或 finish_talk 缺省为结束本段时，MUST 回到待唤醒，球或芯片上的提示 MUST 包含「胖宝」。

#### Scenario: 服务端要求续聊

- **WHEN** 话轮结束事件携带 `finish_talk=false` 且非 exit
- **THEN** 控制器 MUST 在 `end`→`start` 后 `beginListen`
- **AND** 字幕 MUST 进入「请说话…」（或等价续听提示）
- **AND** 球旁或芯片旁 MUST NOT 显示该续听提示
- **AND** MUST 重置本轮有效音标志并重新武装既有 5 秒无声 idle
- **AND** MUST NOT 立即 `resume` 唤醒词监听作为唯一下一入口

#### Scenario: 服务端结束本段

- **WHEN** 话轮结束事件携带 `finish_talk=true`，或收到 `exit`，或缺省结束本段
- **THEN** 控制器 MUST 结束本段并恢复唤醒词监听
- **AND** 状态文案 MUST 回到唤醒提示（如「说「胖宝」唤醒我」）
- **AND** 连接仍开时 MUST 先（或经由统一结束路径）发送 `type=end`

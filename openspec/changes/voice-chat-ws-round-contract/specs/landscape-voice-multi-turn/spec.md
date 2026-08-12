## ADDED Requirements

### Requirement: 横屏 MUST 按 finish_talk 决定续听或回唤醒

After a successful landscape voice answer/TTS turn, the controller MUST branch on server `finish_talk` (and `exit`): when `finish_talk` is false, it MUST keep the chat session and re-arm uplink listening with caption「请说话…」without requiring a new wake phrase; when `finish_talk` is true or `exit` applies (or finish_talk defaults to end-segment), it MUST return to wake-word waiting. 预测横屏在成功应答/TTS 话轮结束后，控制器 MUST 按服务端 `finish_talk`（及 `exit`）分支：`finish_talk=false` 时 MUST 保持 chat 会话并以「请说话…」重新武装上行聆听，MUST NOT 要求再次唤醒词；`finish_talk=true`、适用 `exit`、或 finish_talk 缺省为结束本段时，MUST 回到待唤醒。

#### Scenario: 服务端要求续聊

- **WHEN** 话轮结束事件携带 `finish_talk=false` 且非 exit
- **THEN** 控制器 MUST 在 `end`→`start` 后 `beginListen`
- **AND** 状态文案 MUST 进入「请说话…」（或等价续听提示）
- **AND** MUST 重置本轮有效音标志并重新武装既有 5 秒无声 idle
- **AND** MUST NOT 立即 `resume` 唤醒词监听作为唯一下一入口

#### Scenario: 服务端结束本段

- **WHEN** 话轮结束事件携带 `finish_talk=true`，或收到 `exit`，或缺省结束本段
- **THEN** 控制器 MUST 结束本段并恢复唤醒词监听
- **AND** 状态文案 MUST 回到唤醒提示（如「说「你好，胖宝」唤醒我」）
- **AND** 连接仍开时 MUST 先（或经由统一结束路径）发送 `type=end`

### Requirement: idle 退下 MUST end 再回唤醒

When the landscape 5-second no-effective-speech idle timer fires, the controller MUST run the existing leave UX (caption/asset「我先退下了」) and MUST ensure `type=end` is sent on the open chat socket before restoring wake-word listening. 当横屏 5 秒无有效音 idle 定时器触发时，控制器 MUST 走既有退下 UX（文案/资产「我先退下了」），并 MUST 在恢复唤醒词监听之前确保已在仍打开的 chat 套接字上发送 `type=end`。

#### Scenario: 连续对话中无声超时

- **WHEN** 续听「请说话…」后 5 秒内无有效音
- **THEN** MUST 播退下提示并回待唤醒
- **AND** MUST 向服务端发送 `type=end`
- **AND** MUST NOT 保持服务端侧未 end 的已 start 会话窗

### Requirement: 请说话假死时 MUST 可经话筒恢复

While the landscape UI shows an armed listen caption such as「请说话…」, the listen chip tap MUST remain able to recover from a stuck turn: it MUST NOT be permanently blocked solely by a wake-time `_turnBusy` latch, and MUST be able to force round reset (`end` / stop mic / clear busy) and either re-listen or return to wake. 当横屏 UI 处于「请说话…」等已武装聆听文案时，监听芯片点击 MUST 仍能从卡住的话轮恢复：MUST NOT 仅因唤醒时置位的 `_turnBusy` 而永久拦截；MUST 能强制轮次复位（`end` / 停麦 / 清忙）并重新开听或回唤醒。

#### Scenario: 卡在请说话时点击话筒

- **WHEN** 状态为「请说话…」且上行无进展或忙标记未清
- **THEN** 用户点击话筒芯片 MUST 能触发恢复路径（重新开听或退出本段回唤醒）
- **AND** MUST NOT 无日志地直接 return

### Requirement: 开听武装后 MUST 收窄忙锁

After `beginListen` successfully arms uplink for the current utterance, the controller MUST clear or narrow the wake `_turnBusy` latch so that subsequent chip taps and server-driven continue-listen paths are not blocked for the entire remainder of the turn. 在 `beginListen` 成功武装本轮上行后，控制器 MUST 清除或收窄唤醒期 `_turnBusy`，使后续芯片点击与服务端驱动的续听路径不会在整段话轮剩余时间内被永久阻塞。

#### Scenario: beginListen 成功后可再点芯片

- **WHEN** 唤醒流程已成功 `beginListen` 且文案为「请说话…」
- **THEN** `_turnBusy`（或等价锁）MUST 不再阻止 `onListenChipTap` 的恢复语义

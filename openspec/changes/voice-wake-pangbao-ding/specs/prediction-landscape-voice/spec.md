## MODIFIED Requirements

### Requirement: 预测横屏 MUST 前台常驻唤醒监听（Android 与 iOS）

While the shared prediction voice session is active and the app is in the foreground, the client MUST run on-device wake-word listening for the phrase **「胖宝」** on **both Android and iOS**, in landscape and in portrait, without requiring the user to press a hold-to-talk control. The keyword line MUST keep boost `:2.0` and threshold `#0.25`. `keywordsThreshold` MUST stay `0.25` and `keywordsScore` MUST stay `1.5`. The client MUST NOT raise any of these scores to compensate for the shorter phrase. Listening MUST continue across orientation changes while the session stays active. Listening MUST stop when the session is inactive, the app is backgrounded, or the controller is disposed. The client MUST NOT require background / lock-screen always-on wake. 共享预测语音会话在前台激活时，客户端 MUST 在 **Android 与 iOS**、横屏与竖屏上对唤醒词 **「胖宝」** 常驻本地监听，MUST NOT 要求用户按住说话。关键词行 MUST 保持 `:2.0` 与 `#0.25`；`keywordsThreshold` MUST 保持 `0.25`，`keywordsScore` MUST 保持 `1.5`；MUST NOT 因词变短而调高这些分数。会话仍激活时旋转方向 MUST 继续监听。会话未激活、进后台或控制器 dispose 时 MUST 停止。MUST NOT 要求后台/锁屏常听唤醒。

#### Scenario: Android 横屏前台开始听

- **WHEN** 用户在 Android 进入已激活的预测语音、App 前台且麦克风权限已授予
- **THEN** 客户端 MUST 启动对「胖宝」的本地唤醒监听
- **AND** MUST NOT 提高既有唤醒分数阈值

#### Scenario: iOS 横屏前台开始听

- **WHEN** 用户在 iOS 进入已激活的预测语音、App 前台且麦克风权限已授予
- **THEN** 客户端 MUST 启动对「胖宝」的本地唤醒监听

#### Scenario: 旋转后继续听

- **WHEN** 预测语音会话已激活，用户在横屏与竖屏之间旋转
- **THEN** 客户端 MUST 继续监听「胖宝」
- **AND** MUST NOT 因方向变化改用另一套唤醒词或另一套分数

#### Scenario: 进后台停止听

- **WHEN** App 从已激活的预测语音进入后台
- **THEN** 客户端 MUST 停止本地唤醒监听
- **AND** MUST NOT 在后台继续采集麦克风用于唤醒

### Requirement: 唤醒后 MUST 本地播放「我在」并展示字幕

On wake-word detection, the client MUST show **「我在」** in the subtitle region and MUST start uplink listening without waiting for the acknowledgement sound to finish. The acknowledgement sound MUST be a short local **叮** played asynchronously, and MUST NOT be the spoken asset 「我在」. The client MUST NOT wait for server TTS for this acknowledgement. 检测到唤醒词后，客户端 MUST 在字幕区展示「我在」，并 MUST 在不等待确认音结束的情况下开始上行聆听。确认音 MUST 是异步播放的短本地「叮」，MUST NOT 再播放人声「我在」。该确认 MUST NOT 等待服务端 TTS。

#### Scenario: 唤醒播报

- **WHEN** 本地 KWS 命中「胖宝」
- **THEN** 字幕区 MUST 出现「我在」
- **AND** 客户端 MUST 异步播放短「叮」
- **AND** MUST 立即开始 `beginListen`，不得等「叮」播完

### Requirement: 左下角监听状态 UI

In landscape prediction, the client MUST show a listening affordance anchored to the **physical screen** bottom-start (left in LTR), not merely the event-grid pane's bottom-start (i.e. it MAY overlay the identity rail region). The affordance MUST include an icon and horizontal caption text that wraps when too long. While waiting for wake, the caption MUST communicate wake-word guidance including 「胖宝」. In-turn statuses 「请说话」「连接中」「语音通道连接中」 and 「正在接通会话」, and the wake acknowledgement 「我在」, MUST be shown as subtitles with the same breathing opacity animation as thinking subtitles, not as that caption. The portrait voice ball MUST use the same caption split. Failure text that the user can tap to retry MUST remain on the affordance. 预测横屏 MUST 在**整屏**左下（LTR）展示监听入口（MUST NOT 仅相对事件网格左下；MAY 叠在身份栏区域之上）：图标 + 横向说明文案，超长 MUST 换行。待唤醒文案 MUST 包含「胖宝」。「请说话」「连接中」「语音通道连接中」「正在接通会话」以及唤醒确认「我在」MUST 作为字幕展示，并 MUST 使用与思考字幕相同的呼吸透明度，MUST NOT 写在该入口文案上。竖屏语音球 MUST 使用同一分工。可点按重试的失败文案 MUST 留在入口上。

#### Scenario: 整屏左下角可见

- **WHEN** 预测页横屏且语音监听功能启用
- **THEN** 监听图标与待唤醒说明文案 MUST 锚定在屏幕物理左下附近（相对整页布局，而非仅瀑布流面板）
- **AND** 待唤醒文案 MUST 包含「胖宝」

#### Scenario: 回合状态不写在球旁

- **WHEN** 会话进入请说话或连接中
- **THEN** 该状态 MUST 出现在字幕区，并 MUST 使用与思考字幕相同的呼吸透明度
- **AND** 球旁或芯片旁 MUST NOT 再显示这句状态

### Requirement: 横屏语音 MUST 在平放远场验收集上可识别小声

On **both Android and iOS**, when the device is placed **flat with the screen facing up**, the smart prediction page is in **landscape** and **foreground**, and the user speaks at approximately **2 meters** at **normal quiet volume** after wake, the client MUST achieve reliable ASR for a defined utterance set. Success MUST mean at least **8 of 10** fixed short Chinese test utterances produce usable `asr_partial` and semantically acceptable `asr_final` (or equivalent dialogue outcome) on each platform using representative devices. Wake-word detection at the same fixture MUST use the shared PCM capture configuration and the phrase 「胖宝」, without raising keyword scores. 在 **Android 与 iOS** 上，当设备 **平放且屏幕朝上**、智能预测页 **横屏且前台**、用户唤醒后于约 **2 米**以**正常小声**说话时，客户端 MUST 在定义的 utterance 集上可靠完成 ASR。成功 MUST 定义为：各平台代表机型上，固定 10 句中文短句中至少 **8 句**产生可用 `asr_partial` 与语义可接受的 `asr_final`（或等价对话结果）。同一场景下的唤醒词检测 MUST 使用共享 PCM 采集配置与「胖宝」，且 MUST NOT 调高关键词分数。

#### Scenario: Android 平放 2m 小声对话

- **WHEN** Android 代表机型平放屏朝上、预测横屏前台、用户约 2m 以正常小声说出测试句之一
- **THEN** 客户端 MUST 在 ≥8/10 句上产生可接受的 ASR 结果
- **AND** MUST NOT 因 5s 无有效音 idle 在用户尚未完成有效开口前过早退下（在已触发有效音的轮次）

#### Scenario: iOS 平放 2m 小声对话

- **WHEN** iOS 代表机型平放屏朝上、预测横屏前台、用户约 2m 以正常小声说出测试句之一
- **THEN** 客户端 MUST 在 ≥8/10 句上产生可接受的 ASR 结果

#### Scenario: 2m 小声唤醒

- **WHEN** 用户在上述平放 2m 场景以正常小声说出唤醒词「胖宝」
- **THEN** 客户端 MUST 在验收集上达到与对话段一致的唤醒成功率目标（≥8/10）
- **AND** KWS PCM 采集 MUST 与 chat 上送共用 `AppVoiceRecordConfig`
- **AND** MUST NOT 通过调高唤醒分数来达成该目标

## ADDED Requirements

### Requirement: 主壳回到前台 MUST 重建空闲唤醒流

When the home shell resumes and the shared prediction voice session is active but not inside an uplink listen, thinking window, or reply TTS playback, the client MUST rebuild the wake capture by stopping the chat mic if any, pausing wake listening so the existing PCM subscription is cleared, then resuming wake listening so a new stream is started. Calling resume alone while the previous subscription is still held MUST NOT count as this rebuild. If a turn-end restore is already performing this rebuild, a second call MUST NOT start another capture. 主壳回到前台且共享预测语音已激活、但不在上行聆听、思考窗或回复 TTS 播放中时，客户端 MUST 先停掉对话麦（若有），再 pause 唤醒监听以清掉既有 PCM 订阅，然后 resume 以启动新流。订阅仍在时只调用 resume MUST NOT 算完成重建。若话轮结束恢复已在做同一重建，第二次调用 MUST NOT 再开一路采集。

#### Scenario: 后台回来唤醒流已断

- **WHEN** 用户从后台回到主壳，语音会话仍激活且当前不在聆听、思考或 TTS
- **AND** 唤醒订阅对象还在，但系统侧麦克风流已经停止
- **THEN** 客户端 MUST 先 pause 再 resume
- **AND** 用户随后说出「胖宝」MUST 能再次命中

#### Scenario: 回合进行中不重建

- **WHEN** 主壳回到前台时用户仍处于上行聆听、思考窗或回复 TTS
- **THEN** 客户端 MUST NOT 为了重建唤醒流打断该回合

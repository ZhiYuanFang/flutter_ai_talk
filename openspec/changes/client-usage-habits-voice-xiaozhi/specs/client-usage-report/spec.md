## ADDED Requirements

### Requirement: Landscape surface events MUST report prediction cast and trends orientation

The client SHALL report a usage event when the user confirms entering prediction cast/landscape lock (after the cast confirm dialog succeeds). The client SHALL report a usage event when the trends screen transitions from portrait to landscape orientation (including cold start already in landscape while the trends screen is shown). Landscape→portrait transitions MUST NOT emit the trends landscape show event. Prediction layout list/grid toggles remain separate events and MUST NOT substitute for the cast landscape event.

客户端必须在预测页确认进入投屏横屏时上报；必须在趋势页竖→横（含展示时已是横屏的冷启补报）时上报；趋势横→竖不得报该事件；不得用列表/瀑布切换代替投屏横屏事件。

#### Scenario: Prediction cast landscape confirmed

- **WHEN** 用户在预测页确认「已投屏」且客户端开始锁定横屏
- **THEN** 客户端必须上报稳定 `featureId`（如 `page_prediction_landscape_cast`）与表明进入投屏横屏的中文 `description`
- **AND** 上报调用不得阻塞投屏锁定流程（fire-and-forget）

#### Scenario: Trends portrait to landscape

- **WHEN** 趋势页可见且设备方向从竖屏变为横屏
- **THEN** 客户端必须上报稳定 `featureId`（如 `page_trends_landscape_show`）
- **WHEN** 趋势页在横屏下冷启或首次挂载且当前已是横屏
- **THEN** 客户端必须补报一次趋势横屏展示事件

### Requirement: Voice habit events MUST distinguish wake sources and report truncated user ASR only

The client SHALL report distinct usage events for: (1) keyword-spotting wake from idle waiting-to-wake, (2) listen-chip / portrait edge-dock tap that actually starts a wake listen (excluding mic-retry-only, TTS-playing ignore, and force-reset dismiss paths), and (3) barge-in wake during the thinking window. Portrait and landscape prediction voice MUST share the same reporting paths via the shared voice controller. On each successful user `asr_final` with non-empty text, the client SHALL report a turn event whose `description` includes only the user utterance (MUST NOT include assistant reply text), truncated to the report field length limit. Empty ASR MUST NOT emit a turn report. All voice reports MUST be fire-and-forget and MUST NOT await on the wake/listen critical path.

客户端必须分别上报：待唤醒 KWS、真正开听的点击唤醒、思考窗 barge-in；竖横同一 controller；仅对非空用户 ASR 截断上报且不得含 AI 回复；语音热路径不得 await 上报。

#### Scenario: KWS wake from idle

- **WHEN** 用户在待唤醒状态通过唤醒词进入对话开听
- **THEN** 客户端必须上报 `voice_wake_kws`（或等价稳定 id），且不得同时记为点击唤醒或 barge-in

#### Scenario: Tap wake starts listen

- **WHEN** 用户点击横屏监听 chip 或竖屏贴边球且路径真正触发开听唤醒
- **THEN** 客户端必须上报 `voice_wake_tap`
- **WHEN** 点击仅用于麦克风重试、TTS 播中被忽略、或强制退下假死复位
- **THEN** 客户端不得上报 `voice_wake_tap`

#### Scenario: Barge-in during thinking

- **WHEN** 思考窗内用户以唤醒词打断并进入 barge-in 重开听
- **THEN** 客户端必须上报独立 `voice_wake_barge_in`，不得并入 `voice_wake_kws`

#### Scenario: User ASR truncated only

- **WHEN** 语音会话收到非空用户 `asr_final`
- **THEN** 客户端必须上报 `voice_turn_user`（或等价），`description` 须体现用户话语且长度遵守 report 上限
- **AND** `description` 不得包含 AI 回复正文
- **WHEN** ASR 文本为空
- **THEN** 客户端不得上报该轮用户对话事件

### Requirement: Xiaozhi speaker funnel clicks MUST report on intent taps

The client SHALL report when the Xiaozhi speaker settings page becomes visible. The client SHALL report on tap of: the add-speaker button, the Xiaozhi console hyperlink (any surface using the shared open helper), the buy-howto help icon, and the add-dialog submit「添加」button. These click reports MUST emit even when subsequent unlock/bind/validation fails or the user cancels later. Success of binding MUST NOT be required for click reports.

客户端必须上报小智音箱页展示，以及添加音箱、控制台链接、购买问号、弹窗添加确认的点击；点击后失败或取消仍须已报点击；不得以绑定成功为点击上报前提。

#### Scenario: Page show and add button

- **WHEN** 用户进入小智音箱页
- **THEN** 客户端必须上报 `page_xiaozhi_speaker_show`（或等价）
- **WHEN** 用户点击页底「添加音箱」（含需先绑机/开通文案态）
- **THEN** 客户端必须上报 `xiaozhi_add_btn_click`

#### Scenario: Console, buy help, dialog submit

- **WHEN** 用户点击小智控制台超链接
- **THEN** 客户端必须上报 `xiaozhi_console_link_click`
- **WHEN** 用户点击「如何购买」问号入口
- **THEN** 客户端必须上报 `xiaozhi_buy_help_click`
- **WHEN** 用户在添加弹窗点击「添加」
- **THEN** 客户端必须上报 `xiaozhi_add_dialog_submit_click`，即使随后校验或网络失败

### Requirement: Notification preference toggle MUST report on and off

When the user changes the in-app message notification preference switch, the client SHALL report `notification_pref_on` or `notification_pref_off` (or equivalent stable ids) matching the new preference value. The report MUST be fire-and-forget and MUST NOT block preference persistence or push register/unregister side effects.

用户切换应用内消息通知总开关时，客户端必须按新值上报开/关事件；不得因上报阻塞偏好落盘或推送注册副作用。

#### Scenario: Toggle on and off

- **WHEN** 用户将「接收消息通知」从关切换为开
- **THEN** 客户端必须上报开启事件
- **WHEN** 用户将开关从开切换为关
- **THEN** 客户端必须上报关闭事件

### Requirement: Habit usage reports MUST never block primary flows

For all habit events introduced by this change (landscape, voice, xiaozhi, notification), the client SHALL invoke reporting asynchronously without awaiting on UI or voice critical paths, SHALL discard failures silently without user-visible errors, and SHALL prefer missing a report over delaying or failing the primary user action (cast lock, wake/listen, navigation, preference update). Rate-limit drops remain acceptable.

本变更新增习惯事件必须异步上报、失败静默、宁丢点不阻碍投屏/开麦/导航/偏好更新等主流程；限流丢点可接受。

#### Scenario: Voice critical path not awaited

- **WHEN** 客户端在唤醒或开听路径触发上报
- **THEN** 主路径不得因等待 report HTTP 完成而延迟 `beginListen` 或麦克风切换
- **AND** 上报失败时用户不得看到 toast 或对话中断

## 1. 事件字典

- [x] 1.1 在 `app/lib/data/client_usage_events.dart` 按 design D6 增加横屏、语音、小智、通知相关 `ClientUsageEvent` 常量/工厂（含 `voice_turn_user` 截断工厂）
- [x] 1.2 确认 description 经既有 sanitize（禁 `|`、长度上限），与 repository `_maxLen` 一致

## 2. 横屏展示埋点

- [x] 2.1 预测页：投屏确认「已投屏」成功路径 `unawaited` 上报 `page_prediction_landscape_cast`（不得 await 锁横屏）
- [x] 2.2 趋势页：监听 orientation 竖→横边沿上报 `page_trends_landscape_show`；首帧已是横屏时补报一次；横→竖不报

## 3. 语音习惯埋点

- [x] 3.1 在 KWS `detections` → 待唤醒进对话路径上报 `voice_wake_kws`（勿与 barge-in 混用）
- [x] 3.2 在 `onListenChipTap` 真正开听分支上报 `voice_wake_tap`；排除麦重试 / TTS 忽略 / forceReset 退下
- [x] 3.3 在 `_onBargeInWake` 入口上报 `voice_wake_barge_in`
- [x] 3.4 在非空 `VoiceChatAsrFinal` 上报 `voice_turn_user`（仅用户句截断）；全部 `unawaited`，不串进 await 链

## 4. 小智点击漏斗

- [x] 4.1 小智音箱页挂 `ClientUsageShowOnce`（或等价）上报 `page_xiaozhi_speaker_show`
- [x] 4.2 「添加音箱」按钮点击上报 `xiaozhi_add_btn_click`（含禁用文案态仍点时）
- [x] 4.3 控制台超链接（共享 open helper / LinkedText）点击上报 `xiaozhi_console_link_click`
- [x] 4.4 购买问号入口点击上报 `xiaozhi_buy_help_click`
- [x] 4.5 添加弹窗「添加」点击上报 `xiaozhi_add_dialog_submit_click`（校验失败前亦可报）

## 5. 消息通知

- [x] 5.1 通知设置页开关 `setEnabled` 时按新值上报 `notification_pref_on` / `notification_pref_off`（`unawaited`）

## 6. 验收

- [x] 6.1 手工核对：登录下触发各路径，Debug `[ClientUsage]` 可见对应 featureId；未登录不请求
- [x] 6.2 核对语音热路径无 await report；上报失败不 toast、不阻断开麦/投屏/导航
- [x] 6.3 不新增 `**/test/**` 测试文件

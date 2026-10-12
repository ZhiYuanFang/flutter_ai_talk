## Why

运维需要从 client-usage 日志观察用户是否养成横屏投屏/趋势横屏、语音对话（含打断思考）、小智音箱探索与消息通知开关等习惯；现有上报仅覆盖页展示与少量动作，缺少上述关键路径，无法判断「有没有意愿操作」与「有没有真正开口说话」。

## What Changes

- 扩展 `ClientUsageEvents` 字典与埋点调用点，新增：
  - 预测页确认进入投屏横屏
  - 趋势页设备旋转进入横屏（竖→横边沿各报一次）
  - 语音：语音唤醒 / 点击唤醒 / 思考窗 barge-in 打断（三路独立 featureId）；用户 ASR 一句截断上报（不报 AI 回复）；竖屏与横屏共用同一语音 controller 路径
  - 小智音箱：进页展示；添加音箱按钮、控制台超链接、购买问号、弹窗「添加」均为**点击即报**（不要求成功）
  - 消息通知偏好开启 / 关闭
- 明确原则：**上报不得阻碍主流程**（fire-and-forget、`unawaited`、失败静默、宁丢点不卡顿）；不改服务端 API 契约。
- 无 **BREAKING**；未登录仍不调用上报接口。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `client-usage-report`：在既有静默上报与页展示要求之上，新增横屏展示、语音习惯、小智点击漏斗、通知开关等动作/展示事件的 Requirement 与 Scenario。

## Impact

- **代码**：`app/lib/data/client_usage_events.dart`；`landscape_voice_provider.dart`（唤醒/ASR 分流）；`smart_prediction_screen.dart`（投屏确认）；`trends_screen.dart`（orientation 边沿）；`xiaozhi_speaker_screen.dart` / `xiaozhi_console_link.dart`；`notification_settings_screen.dart`；可选 `ClientUsageShowOnce` 挂小智页。
- **API**：仍用 `POST /device/app/api/client-usage/report`（`featureId` + `description`，≤128，禁 `|`）；同账号约 3s 限流丢点可接受。
- **规格**：对照基线 `openspec/specs/v2.1.3.md` 能力 `client-usage-report` 增量；不改语音协议、小智绑定业务逻辑本身。

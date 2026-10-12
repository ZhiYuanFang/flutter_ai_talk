## Context

客户端已有 `ClientUsageReporter` / `ClientUsageEvents` / `POST /device/app/api/client-usage/report`：登录才报、失败静默、字段 ≤128 且禁 `|`、同账号约 3s 限流。基线 `client-usage-report` 已覆盖主壳/UCG/路由页展示与预测开关、布局、主题、头像等动作。

缺口：预测投屏横屏、趋势旋转横屏、语音习惯（唤醒来源 / barge-in / 用户话术）、小智探索点击漏斗、消息通知开关。语音竖横共用 `LandscapeVoiceController`，适合在 controller 内统一埋点。

## Goals / Non-Goals

**Goals:**

- 用稳定 `featureId` + 运维可读中文 `description` 覆盖探索结论中的习惯事件。
- 语音三路唤醒（KWS / 点击 / barge-in）可分列统计；用户 ASR 截断上报；竖屏贴边球与横屏 chip 同一套。
- 小智相关点击即报，便于观察「有意愿但未完成」。
- 上报 **fire-and-forget**：不 await 热路径、不 toast、不因上报异常阻断业务。

**Non-Goals:**

- 不改服务端 report API、不加长字段、不做批量队列。
- 不上报 AI 回复全文；不做会话级聚合日志。
- 不给趋势页新增投屏锁定入口（仅 orientation 边沿）。
- 不新建 `**/test/**` 测试文件。

## Decisions

### D1：增量扩展事件字典，不新造上报通道

- **选择**：在 `client_usage_events.dart` 增加常量/工厂，调用点 `unawaited(reporter.reportEvent(...))`。
- **理由**：契约与限流策略已落地；运维时间线已按 featureId 聚合。
- **备选**：专用对话日志 API → 超出范围、需服务端。

### D2：语音来源在汇合前分报

```
KWS detections        → voice_wake_kws（待唤醒进对话）
onListenChipTap 开听  → voice_wake_tap（排除仅重试麦、TTS 播中忽略、forceReset 退下）
_onBargeInWake 入口   → voice_wake_barge_in（思考窗打断）
AsrFinal              → voice_turn_user（description 含截断用户句）
```

- **理由**：三者最终都进 `_onWakeDetection`/`_onWake`，汇合后无法区分。
- **竖屏**：贴边球亦调 `onListenChipTap`，自然计入 tap；KWS/barge-in/ASR 同 controller。

### D3：横屏展示两路径语义不同

| 表面 | 触发 | featureId |
|------|------|-----------|
| 预测 | 投屏确认「已投屏」后锁横屏 | `page_prediction_landscape_cast` |
| 趋势 | `Orientation` 竖→横边沿 | `page_trends_landscape_show` |

- **理由**：预测是主动投屏；趋势无 cast 按钮，用旋转观察横屏使用。
- **趋势细节**：每次 portrait→landscape 报一次；landscape→portrait 不报；冷启已是横屏时是否补报——实现时在 TrendsScreen 首帧若已是 landscape 报一次（与「进入横屏可见」一致）。

### D4：小智点击即报

- 进页：`ClientUsageShowOnce` 或等价首帧 show。
- 添加音箱按钮、控制台链接、购买问号、弹窗「添加」：`onPressed`/`onTap` 入口即 `unawaited` 上报，不依赖开通成功或绑定成功。
- **理由**：产品要看意愿漏斗，不是转化成功数。

### D5：宁丢点，不堵主流程（强制）

- 调用侧：语音/点击热路径 **禁止** `await reportEvent`。
- Repository：保持 try/catch 静默；限流/网络失败仅 `[ClientUsage]` Debug。
- description 工厂内截断，避免超长字符串拖慢；ASR 空串跳过上报。

### D6：建议 featureId 对照

| featureId | description 方向 |
|-----------|------------------|
| `page_prediction_landscape_cast` | 预测页进入投屏横屏 |
| `page_trends_landscape_show` | 趋势页旋转进入横屏 |
| `voice_wake_kws` | 语音唤醒 |
| `voice_wake_tap` | 点击唤醒 |
| `voice_wake_barge_in` | 语音打断思考 |
| `voice_turn_user` | `语音对话（用户）：…`（截断） |
| `page_xiaozhi_speaker_show` | 展示小智音箱页 |
| `xiaozhi_add_btn_click` | 点击添加音箱 |
| `xiaozhi_console_link_click` | 点击小智控制台链接 |
| `xiaozhi_buy_help_click` | 点击如何购买说明 |
| `xiaozhi_add_dialog_submit_click` | 点击添加弹窗确认 |
| `notification_pref_on` / `notification_pref_off` | 开启/关闭消息通知 |

## Risks / Trade-offs

- **[Risk] 3s 限流导致连说多句丢点** → 接受；习惯观察以「有/无」为主，不要求句句必达。
- **[Risk] 128 字截断丢失长句** → description 前缀标明「用户」+ 截断；不扩契约。
- **[Risk] 热路径误 await 导致开麦变慢** → design/tasks 明确禁止；code review 盯语音路径。
- **[Risk] 控制台链接多入口重复 featureId** → 有意统一，便于合计「点过控制台」意愿。

## Migration Plan

- 纯客户端增量；发版即生效；无需数据迁移。
- 回滚：去掉新事件调用与字典常量即可，不影响旧事件。

## Open Questions

- （无阻塞项；冷启趋势已横屏补报按 D3 实现默认。）

## 1. 代码：去掉 WS 提醒调度

- [x] 1.1 在 `app/lib/ui/home_screen.dart` 的 `_onHistoryWebSocketPayload` 中移除 `isNew && !replacesPending` 分支对 `_scheduleActiveTimingReminderAfterAdd` 的调用；清理仅服务于「防双弹提醒」且已无用的局部变量/注释（若 `isNew` / `replacesPending` 不再使用则删除）
- [x] 1.2 确认喂养页 `_onEventGridTap` → `onAdded` → `_scheduleActiveTimingReminderAfterAdd` 仍保留；确认预测页 `handleEventGridTap` 未挂接提醒 `onAdded`

## 2. 验收

- [x] 2.1 手工：喂养页在已有进行中计时时用按钮新增另一事件 → 仍弹出「还有计时未结束」
- [x] 2.2 手工：预测页在已有进行中计时时加事件 → 不弹该提醒；列表/飞入仍可正常
- [x] 2.3 手工或联调：他端/另一设备新增记录经 WS 同步到本机 → 不弹该提醒（列表可更新）

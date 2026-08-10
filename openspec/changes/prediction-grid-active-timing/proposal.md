## Why

预测页网格卡在事件已有进行中计时时仍展示指向 `nextAt` 的倒计时，与真实「正在计时」状态冲突。用户需要在网格卡上直接看到已计时长并停止，且保留推演开关；列表态折线卡不改。

## What Changes

- 网格/瀑布流（compact）事件卡：当该事件存在进行中计时历史时，**不得**展示 `nextAt` 倒计时与倒计时上方大图主区。
- 计时中布局：事件图标在事件名左侧；中间展示已计时长（`formatActiveTimerElapsed` 语义）；底部「停止」按钮；标题行**仍保留**推演开关。
- 停止：复用喂养页同一历史更新语义（写 `endTime`、无二次确认）；请求中禁用停止；成功后卡回到非计时（倒计时）态。
- 「停止」命中区**不得**触发整卡加事件；整卡其它区域在计时中 SHOULD 不新开同事件计时（既有加事件守卫可继续生效）。
- **不改**纵向列表态卡片结构与折线/相对时间规则。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `smart-prediction-page`：网格卡增加「进行中计时」专用 chrome；并收窄既有网格倒计时要求（计时中不适用）。

## Impact

- UI：`smart_prediction_screen.dart`（`_PredictionEventCard` compact 分支）；watch `homeHistoryProvider` 解析进行中记录。
- 复用：`isActiveTimingRecord` / `activeTimingStartAt` / `formatActiveTimerElapsed`、`feed.updateHistoryRecord`（或抽出与 `HomeScreen._stopActiveTimer` 共享的停止逻辑，避免双份语义）。
- 秒刷：沿用 `predictionClockProvider`；无 Android/新依赖。

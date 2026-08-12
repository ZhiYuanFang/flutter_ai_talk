## Why

「还有计时未结束」提醒目前在 History WebSocket 推送「纯新增」时也会触发（含他端同步），在预测页加事件经 WS 回声时也可能从仍 keep-alive 的喂养页冒出，打断用户。产品要求：仅喂养页本机按钮 HTTP 新增成功后才判断弹窗；预测页与任何 WS 推送路径均不得弹该提醒。

## What Changes

- **BREAKING（相对基线行为）**：History WS/SSE 推送历史新增时 **MUST NOT** 再调度「还有计时未结束」提醒（他端同步完全静默；本机 echo / 语音回写若仍仅靠 WS 落库也不再弹）。
- 喂养页事件格 HTTP `add` 成功后的 `onAdded` → 提醒调度 **保持**。
- 智能预测页加事件（网格卡 HTTP）**不得**挂接该提醒（现状无 `onAdded` 提醒；本变更明确为规范要求）。
- 飞入动画等其它 WS 副作用 **不变**。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-active-timing-after-add-reminder`：将触发源收窄为**仅喂养页按钮路径 HTTP 新增成功**；明确 WS 推送与预测页 MUST NOT 弹窗；删除/改写基线中「语音或文字靠 WS 推送弹窗」场景。

## Impact

- 代码：`app/lib/ui/home_screen.dart`（去掉 `_onHistoryWebSocketPayload` 内对 `_scheduleActiveTimingReminderAfterAdd` 的调用）。
- 规格：`home-active-timing-after-add-reminder` delta；对照基线 `openspec/specs/v2.1.0.md`。
- 无 API / 原生 / 依赖变更；飞入与列表 upsert 行为不变。

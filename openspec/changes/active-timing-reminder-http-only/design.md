## Context

基线 `home-active-timing-after-add-reminder` 要求「历史新增成功后」扫描其它进行中计时并弹「还有计时未结束」。实现上喂养 `HomeScreen` 有两条入口：

1. **HTTP**：事件格 `handleEventGridTap` → `onAdded` → `_scheduleActiveTimingReminderAfterAdd`
2. **WS**：`_onHistoryWebSocketPayload` 在 `isNew && !replacesPending` 时同样调度（注释「他端纯新增：补计时提醒」）；该路径也覆盖基线「语音/文字靠 WS 落库」场景

预测页加事件走同一 `submitEventAdd` HTTP，但未传 `onAdded`；若 WS 将回声/他端新增当成纯新增，keep-alive 的喂养页仍会弹窗。产品已确认：仅喂养 HTTP；预测不弹；他端同步完全静默。

## Goals / Non-Goals

**Goals:**

- 仅喂养页按钮路径 HTTP 新增成功后，在存在其它进行中计时时弹提醒（含 fly 结束后再弹的既有编排）。
- History WS 任意推送路径 **不得** 调用提醒调度。
- 预测页 **不得** 挂接该提醒。

**Non-Goals:**

- 不改对话框 UI、多选结束、停止 API、同 eventId 重复开始 Toast。
- 不改飞入动画触发（仍由 WS）。
- 不恢复喂养语音/文字输入；若日后恢复且仅靠 WS 落库，本变更下也不会弹该提醒（接受）。
- 不抽跨页共享提醒编排（预测明确不弹）。

## Decisions

1. **只删 WS 调度，保留喂养 HTTP `onAdded`**  
   最小改动：去掉 `_onHistoryWebSocketPayload` 中 `isNew && !replacesPending` 分支对 `_scheduleActiveTimingReminderAfterAdd` 的调用；`replacesPending` 注释可一并简化（不再为「防双弹提醒」服务，若变量仅服务于提醒则可删局部判断）。

2. **预测页保持无 `onAdded` 提醒**  
   不新增预测侧提醒逻辑；规格写明 MUST NOT，防止后续「对称补全」。

3. **飞入与提醒解耦保持**  
   WS 仍可 `requestHistoryEventFlyAfterMutation`；提醒仅 HTTP。若飞入进行中且 HTTP 已排提醒，既有 `_pendingReminderExcludeId` / fly complete 再 present 逻辑保留。

## Risks / Trade-offs

- **[Risk] 语音/文字若再启用且仅靠 WS 落库 → 不再弹提醒** → 接受；与「仅 HTTP」产品决策一致；日后若需要可改为 HTTP 成功回调或本机意图标记。
- **[Risk] 他端加事件时本机有其它计时 → 无 nudge** → 接受（他端静默）。

## Migration Plan

- 纯客户端行为收窄；无数据迁移。
- 回滚：恢复 WS 分支调度即可。

## Open Questions

（无；产品已确认喂养 HTTP only、预测不弹、他端静默。）

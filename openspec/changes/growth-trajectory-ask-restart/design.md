## Context

成长轨迹提问时，`canShowCta` 把 `asking` 和 `streaming` 一起排除，「重新预测」只在 `hasResult` 且非流式、非提问时出现。

服务端已经支持整轮重来：Flutter `startPredict(restart: true)` 传空 `sessionId`，Go 转发 `action=restart`，Python 在 `session_id` 为空时新建 `gt_` 线程。提问阶段上一次 SSE 已结束，Go 进程内互斥已释放，可以再开。日限只在 `result` 落库时 INCR，未完成的问答不计次。

思考流进行中互斥仍占着，这时再点会被拒成「成长轨迹预测进行中，请稍候」。

## Goals / Non-Goals

**Goals:**

- 提问阶段可以点「重新预测」，丢掉本次问答，从新会话的第一问重新来。
- 仍用现有 restart，不新增接口。

**Non-Goals:**

- 回到上一题、改某一个已提交选项。
- 思考流进行中展示或允许重开。
- 释放 Python `MemorySaver` 里被丢掉的旧线程。
- 改 Go 日限、互斥或 Python 图。
- 提问阶段展示「可以先离开」的等待说明（该说明仍只在流式思考）。
- 新建 `**/test/**`。

## Decisions

### 1. 只在 `asking` 放出按钮

`phase == asking` 且已开通时，正文下方使用现有 `_GrowthBodyCta`，文案「重新预测」，`onTap` 调 `_onPredict(restart: true)`。用量小字沿用 `usageCopy`。

`streaming` / `loadingLatest` 继续不放按钮。有结果、空闲时的按钮逻辑不变。

备选：思考中也可点，失败再 Toast。否决——用户要的是问答反悔；思考中请求还在，点了只会撞锁。

### 2. 不确认弹层

与结果页「重新预测」一样，一点即重开，不插确认框。按钮在选项下方，和选项分开，避免被当成第三题答案。

备选：二次确认。否决——结果页没有确认，两处行为应一致。

### 3. 不改状态机

`_runTurn` 在 restart 时已把阶段设为 `streaming`、清掉当前题、清空思考缓冲，旧 `resultMarkdown` 先留着。思考分支先于结果分支，页面只显示思考区。新 `result` 到达后替换 Markdown。失败且已有旧结果时，现有错误路径回到 `ready`。不在 restart 开始时清空 Markdown。

备选：一点就把旧结果清掉。否决——重开失败会变成空白，而服务端 latest 还在。

## Risks / Trade-offs

- [误点「重新预测」丢掉已答内容] → 与结果页同一手势，不另加确认；按钮不放进选项列表。
- [日限已满时提问中重开被拒] → 走现有 Toast，不在客户端预判次数。未完成的本轮本身没计次，未满限时重开不会多扣。
- [旧线程留在 Python 内存] → 本次不处理，与已约定的断点内存范围一致。

## Migration Plan

仅客户端。发版即生效。回滚即恢复提问阶段不放按钮。

## Open Questions

无。

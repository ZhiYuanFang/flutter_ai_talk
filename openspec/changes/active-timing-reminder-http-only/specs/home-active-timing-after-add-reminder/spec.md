## MODIFIED Requirements

### Requirement: 新增成功后检测其它进行中计时

The system SHALL, after a feeding-page button-path history record is successfully added via HTTP, scan persisted history for active timing records other than the newly added record and prompt the user when at least one exists. 系统必须在**喂养页事件按钮路径**通过 HTTP（`addHistoryEvent` / `POST /device/history/api/event/add`）**新增成功之后**，扫描当前历史列表中除**刚新增记录**外的其它记录；若存在至少一条进行中计时（`isActiveTimingRecord`），则 MUST 向用户展示提醒对话框。刚新增记录的 id 必须排除在候选之外。`isPendingHistoryId` 的记录不得作为可停止候选。智能预测页加事件 MUST NOT 展示本提醒。History WebSocket/SSE 推送导致的列表变更 MUST NOT 调度或展示本提醒（含他端同步、本机 echo、以及仅靠 WS 落库的语音/文字回写）。

#### Scenario: 喂养按钮 HTTP 新增后存在其它计时

- **WHEN** 用户在喂养页通过事件按钮成功新增一条记录，且列表中另有至少一条其它进行中计时
- **THEN** 系统必须在适当时机（fly 动画结束后或若无动画则新增成功后的下一帧）展示提醒对话框

#### Scenario: 预测页 HTTP 新增不弹提醒

- **WHEN** 用户在智能预测页通过网格卡成功新增一条记录，且列表中另有其它进行中计时
- **THEN** 系统 MUST NOT 展示本提醒对话框

#### Scenario: History WS 推送不弹提醒

- **WHEN** History WebSocket/SSE 推送一条新历史记录（含他端同步或本机操作回声），且列表中另有其它进行中计时
- **THEN** 系统 MUST NOT 因该推送展示本提醒对话框
- **AND** 列表 upsert / 飞入等其它既有副作用 MAY 仍按对应能力执行

#### Scenario: 无其它进行中计时

- **WHEN** 喂养页按钮 HTTP 新增成功后，除刚新增记录外不存在其它进行中计时
- **THEN** 系统不得展示本提醒对话框

#### Scenario: 新增未成功

- **WHEN** 喂养页按钮新增 API 失败
- **THEN** 系统不得展示本提醒对话框

## ADDED Requirements

### Requirement: 提醒触发源仅限喂养 HTTP onAdded

The client MUST schedule the active-timing reminder only from the feeding page event-grid HTTP success callback (`onAdded` / equivalent), and MUST NOT schedule it from History WS payload handlers. 客户端 MUST 仅从喂养页事件格 HTTP 成功回调调度本提醒；MUST NOT 在 History WS payload 处理函数中调度本提醒。

#### Scenario: WS 处理函数无提醒调度

- **WHEN** `HomeScreen`（或等价）处理 History WS upsert/create 载荷
- **THEN** 该处理路径 MUST NOT 调用 `_scheduleActiveTimingReminderAfterAdd`（或等价提醒调度入口）

## ADDED Requirements

### Requirement: WebSocket 新增 record 触发飞行动画

The home screen MUST start the event icon fly animation when a history WebSocket/SSE payload represents a **new** record (record id not present in local state before upsert). 主页必须在历史 **WebSocket/SSE** 推送**新增** record（upsert 前本地不存在该 `id`）时启动事件图标飞行动画；**不得**在仅 `update` 同 id（如停止计时）或 `delete` 时触发。

#### Scenario: 按钮添加 one 型事件

- **WHEN** 用户通过底部按钮成功落库且 WS 推送带新 `record.id`
- **THEN** 系统必须启动飞行动画，且动画绑定该 `record.id`

#### Scenario: 停止计时 update

- **WHEN** WS 推送更新已有计时 record（同 `id`）
- **THEN** 系统不得播放飞行动画

#### Scenario: 删除 record

- **WHEN** WS 推送 `removedRecordId`
- **THEN** 系统不得播放飞行动画

### Requirement: 飞行动画视觉路径

The fly animation SHALL display the event icon at the history area center, briefly scale up, then animate toward the bottom target while scaling down to logo size. 飞行动画必须：在历史区可视中心显示该事件 **EventLogo** → 短暂放大 → 缩小并飞向底部目标位置。

#### Scenario: 正常完成

- **WHEN** 新增 record 触发动画且测点成功
- **THEN** 用户必须看到中心出现图标、略放大、再飞向底部目标；飞行期间列表内该 logo 可隐藏，动画结束后显现

#### Scenario: 减少动效开启

- **WHEN** `MediaQuery.disableAnimations` 为 true
- **THEN** 系统必须跳过 Overlay 飞行动画，仍正常 upsert；若处于跟底状态则仍滚底

### Requirement: 目标锚点按 recordId 定位

The animation target MUST be derived from the EventLogo anchor of the pushed record id. 动画终点必须基于推送 **record.id** 对应行的 **EventLogo** 锚点测量；**不得**仅用 `fromBottom == 0` 启发式。

#### Scenario: 跟底且锚点可见

- **WHEN** 用户处于列表底部且锚点 rect 有效
- **THEN** 飞行终点必须与锚点中心对齐（允许 ±1 logical px）

#### Scenario: 测点失败

- **WHEN** 连续最多 2 帧仍无法获得有效锚点
- **THEN** 系统必须静默跳过飞行动画

### Requirement: 滚动策略 B+（非底部不滚底仍飞入）

When the user is not following the latest records, the history list MUST NOT auto-scroll to bottom on new record, but the fly animation MUST still play toward the bottom target. 当用户**未**处于跟底状态时，新增 record **不得**自动滚底，**仍必须**播放飞向底部目标的动画；当用户**处于**跟底状态时，**必须**滚底后再飞入锚点。

#### Scenario: 用户翻看旧记录时新增

- **WHEN** 列表 scroll 偏移表明未跟底，且 WS 推送新增 record
- **THEN** 列表必须保持当前 scroll 位置不变，且必须播放飞向底部目标的动画

#### Scenario: 用户在底部时新增

- **WHEN** 列表已跟底且 WS 推送新增 record
- **THEN** 列表必须滚到底部并播放飞入该 record logo 的动画

#### Scenario: 非跟底且锚点在视口外

- **WHEN** 锚点中心位于历史视口下方
- **THEN** 动画可见落点必须为历史区**底缘中心**（或 design 约定的底缘落点），以表达「落入底部」

### Requirement: 并发与数据流隔离

Fly animation MUST NOT alter event add API, WebSocket subscription, or upsert/remove logic beyond scheduling overlay UI. 飞行动画 **不得**改变 add/WS/upsert 语义。快速连续新增时 **必须** 取消尚未完成的飞行，以最新 record 为准。

#### Scenario: 连续两次快速添加

- **WHEN** 短时间内 WS 连续推送两个新 record id
- **THEN** 飞行动画以最后一次为准，两条记录均正常出现在列表中

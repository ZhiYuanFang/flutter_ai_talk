## MODIFIED Requirements

### Requirement: WebSocket 新增 record 触发飞行动画

The home screen MUST start the event icon fly animation when a history record is newly introduced to local state, either via WebSocket/SSE (id not present before upsert) or via button-path optimistic insert (`pending:<uuid>`); the animation MUST NOT run again for the same logical add when id is replaced or when WebSocket merges an existing id. 主页必须在历史记录**首次**进入本地状态时启动飞行动画：包括 WebSocket/SSE 新增（upsert 前本地不存在该 id），以及按钮强乐观插入的 `pending:<uuid>`；当 pending 替换为服务端 id 或 WS 推送**已存在**的 id 时**不得**再次触发。

#### Scenario: 按钮乐观添加

- **WHEN** 用户通过底部按钮完成乐观插入（pending 行）
- **THEN** 系统必须在 tap 路径启动一次飞行动画，绑定该 `pending:<uuid>`

#### Scenario: add 成功 id 替换

- **WHEN** pending id 被替换为服务端 id
- **THEN** 系统不得播放第二次飞行动画

#### Scenario: WS 对账已存在 id

- **WHEN** WS 推送 create/update 且 `record.id` 已在本地列表中
- **THEN** 系统不得播放飞行动画

#### Scenario: 按钮添加 one 型（修订：不再仅 WS）

- **WHEN** 用户通过底部按钮添加 one 型事件且走乐观路径
- **THEN** 飞行动画在乐观插入时触发，**不必**等待 WS 才触发

#### Scenario: 停止计时 update

- **WHEN** WS 推送更新已有计时 record（同 `id`）
- **THEN** 系统不得播放飞行动画

#### Scenario: 删除 record

- **WHEN** WS 推送 `removedRecordId`
- **THEN** 系统不得播放飞行动画

### Requirement: 并发与数据流隔离

Fly animation MUST NOT alter add API semantics beyond scheduling overlay UI; optimistic add and id replacement are owned by `home-event-optimistic-add`. 飞行动画**不得**改变 add/WS/upsert 业务语义；乐观插入与 id 替换由 `home-event-optimistic-add` 负责。快速连续按钮添加时**必须**取消尚未完成的飞行，以最新触发的 record id 为准。

#### Scenario: 连续两次快速按钮添加

- **WHEN** 用户短时间内两次乐观插入不同 pending id
- **THEN** 飞行动画以最后一次为准，两条记录均保留（或失败各自回滚）

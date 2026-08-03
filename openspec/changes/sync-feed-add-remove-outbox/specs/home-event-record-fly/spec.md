## MODIFIED Requirements

### Requirement: WebSocket 新增 record 触发飞行动画

The home screen MUST start the event icon fly animation when History WebSocket/SSE delivers a create (or equivalent new-record upsert) that the client treats as fly-worthy: (1) the record id was not present locally before upsert (`isNew`), or (2) the id was pre-inserted by a successful button-path HTTP add and is registered as awaiting WS fly. Button-path HTTP success MUST insert/update the list and MUST NOT start the fly animation. Ordinary WS updates for an already-local id that is not awaiting WS fly MUST NOT fly. 主页飞入 **必须** 由 History WS/SSE 触发：真正新 id（upsert 前本地不存在），或本机按钮 HTTP 已入列并登记「等待 WS 飞入」的 id。按钮路径 HTTP 成功 **必须** 入列且 **不得** 启动飞入。对已在本地且非 awaiting 的同 id 普通 update **不得** 飞入。

#### Scenario: 按钮 HTTP 成功不飞入

- **WHEN** 用户通过底部按钮 add HTTP 成功并以服务端 id 插入或合并列表
- **THEN** 系统 MUST NOT 在该 HTTP 成功路径启动飞行动画
- **AND** MUST 登记该 id 等待后续 WS 飞入（若本地此前不存在该 id）

#### Scenario: WS 对本机 HTTP 已插入 id 飞入

- **WHEN** 本机 HTTP 已插入 serverId 并登记 awaiting
- **AND** WS 推送同 id 的 create/update
- **THEN** 系统必须启动一次飞行动画并清除 awaiting
- **AND** MUST NOT 因 `isNew == false` 而跳过飞入

#### Scenario: WS 他端真正新增飞入

- **WHEN** WS 推送 create 且 upsert 前本地不存在该 id（非本机 HTTP 预插）
- **THEN** 系统必须启动一次飞行动画

#### Scenario: WS 普通 update 不飞入

- **WHEN** WS 推送 update 且 id 已在本地且不在 awaiting 集合
- **THEN** 系统不得播放飞行动画

#### Scenario: 停止计时 update

- **WHEN** WS 推送更新已有计时 record（同 `id`，非 awaiting）
- **THEN** 系统不得播放飞行动画

#### Scenario: 删除 record

- **WHEN** WS 推送 `removedRecordId`
- **THEN** 系统不得播放飞行动画

### Requirement: 并发与数据流隔离

Fly animation MUST NOT alter add API semantics beyond scheduling overlay UI; HTTP sync-success insert is owned by `home-event-optimistic-add`, while fly ownership remains on the WS path. 飞行动画**不得**改变 add/WS/upsert 业务语义；HTTP 成功入列由 `home-event-optimistic-add` 负责，飞入由 WS 路径负责。快速连续添加时**必须**取消尚未完成的飞行，以最新触发的 record id 为准。

#### Scenario: 连续两次 WS 飞入

- **WHEN** 用户连续两次按钮添加且两次 WS create 均到达
- **THEN** 飞行动画以最后一次为准，两条服务端记录均保留在列表中

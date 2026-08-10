## MODIFIED Requirements

### Requirement: WebSocket 新增 record 触发飞行动画

The home feeding and smart-prediction surfaces MUST start the shared event-icon fly animation when History WebSocket/SSE delivers any history mutation (create/upsert/update or remove) while that surface is the current visible home PageView page, provided a usable landing anchor can be prepared and measured for the page-specific target. The animation MUST NOT be gated on `isNew` or an awaiting-WS-fly registry. Button-path HTTP success MUST insert/update the list and MUST NOT itself start the fly animation (WS remains the fly trigger). Consecutive mutations MAY interrupt prior flights; the latest session MUST win. If no usable anchor exists after prepare, the client MUST NOT fly. 喂养与智能预测在作为当前可见主页时，History WS/SSE 的**任意**历史变动（create/upsert/update 或 remove）MUST 在可测得页内落点锚点时启动共享飞入；MUST NOT 再以 `isNew` 或 awaiting 登记作为飞入门槛。按钮路径 HTTP 成功 MUST 入列且 MUST NOT 自行启动飞入（仍由 WS 触发）。连续变动可打断上一段飞行，以最新 session 为准。prepare 后无可用锚点则 MUST NOT 飞入。

#### Scenario: 按钮 HTTP 成功不飞入

- **WHEN** 用户通过底部按钮 add HTTP 成功并以服务端 id 插入或合并列表
- **THEN** 系统 MUST NOT 在该 HTTP 成功路径启动飞行动画

#### Scenario: WS create 飞入

- **WHEN** WS 推送 create/upsert 且当前可见页为喂养或预测
- **AND** 该页可测得对应落点锚点
- **THEN** 系统必须启动一次飞行动画

#### Scenario: WS 普通 update 飞入

- **WHEN** WS 推送 update（含停止计时等字段合并）且当前可见页为喂养或预测
- **AND** 该页可测得对应落点锚点
- **THEN** 系统必须启动一次飞行动画

#### Scenario: WS 删除无锚点不飞入

- **WHEN** WS 推送 `removedRecordId` 且删除后无法测得落点锚点
- **THEN** 系统 MUST NOT 播放飞行动画

#### Scenario: 不可见页不飞入

- **WHEN** WS 推送历史变动但当前主页不是喂养也不是预测
- **THEN** 系统 MUST NOT 播放飞行动画

#### Scenario: 连续两次 WS 飞入

- **WHEN** 连续两次历史变动均到达且均满足可见页与锚点条件
- **THEN** 飞行动画以最后一次为准

## ADDED Requirements

### Requirement: 飞入与落点解析解耦

The fly overlay MUST accept a page-provided landing target (prepare + global center measure) and MUST NOT hard-require `HomeHistoryScroll` as the only landing source. Feeding MUST land on the history-row EventLogo for the record id when present; prediction landing behavior is defined by `history-fly-visible-landing`. 飞入 Overlay MUST 接受页面提供的落点（prepare + 全局中心测量），MUST NOT 将 `HomeHistoryScroll` 硬编码为唯一落点源。喂养在记录 logo 存在时 MUST 落向该 record 历史行 EventLogo；预测落点行为由 `history-fly-visible-landing` 定义。

#### Scenario: 喂养落点仍为历史 logo

- **WHEN** 喂养页可见且目标 `recordId` 的历史行 logo 锚点可见
- **THEN** 飞入终点 MUST 为该 logo 全局中心

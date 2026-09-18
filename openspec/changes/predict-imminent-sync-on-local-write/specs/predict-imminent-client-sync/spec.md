## MODIFIED Requirements

### Requirement: Client SHALL sync predict-imminent pending after local prediction updates
The client SHALL call `PUT /device/api/predict/imminent/pending` with the full list of events that have a definite `nextAt` (unix seconds), or an empty `events` array to clear server-side schedules, **only after** a **local** feeding-history mutation or a **local** feeding-interval (recall seed) mutation has been applied and the locally computed prediction list has been recomputed from those inputs. 客户端 **必须** 仅在本机喂养记录变更或本机喂养间隔变更已落地、且本地预测已按新输入重算完成后，全量同步预测临近待办（或空列表清空）。

The client MUST NOT sync pending solely because predictions recomputed after pulling latest history/range data (including resume bootstrap and range force reload). 仅因拉取最新数据触发的预测重算 **不得** 同步 pending。

The client MUST NOT sync pending when applying remote feeding-history updates received over WebSocket on this device (peer device is responsible for pending sync). 本机合并他端 WS 喂养历史时 **不得** 同步 pending。

#### Scenario: Sync after local feeding record change
- **WHEN** 用户已登录且本机新增、修改、删除或结束计时一条喂养记录，本地预测已按更新后的历史重算完成
- **THEN** 客户端 MUST 发起 pending 同步；若有确定 `nextAt` 则 body 含对应 `eventId` 与 `nextAt`（秒），否则以空 `events` 清空

#### Scenario: Sync after local feeding interval change
- **WHEN** 用户已登录且本机写入或更新喂养间隔（recall 种子）并导致预测重算完成
- **THEN** 客户端 MUST 发起 pending 同步（规则同上）

#### Scenario: No sync after pull-latest recompute
- **WHEN** 客户端因 bootstrap、resume 或 range `ensureLoaded(force)` 等拉取对齐而重算预测
- **THEN** 客户端 MUST NOT 因此次重算发起 pending 同步

#### Scenario: No sync after peer WS history apply
- **WHEN** 本机经历史 WebSocket 合并他端写入的喂养记录（upsert/remove）并重算预测
- **THEN** 客户端 MUST NOT 因此次合并发起 pending 同步

#### Scenario: Clear when no upcoming after eligible local mutation
- **WHEN** 本机合格变更后预测刷新没有任何可上报的确定 `nextAt`
- **THEN** 客户端 MUST 以空 `events` 同步以清空服务端闹钟

#### Scenario: Failure does not crash
- **WHEN** pending 同步 HTTP 失败
- **THEN** 客户端 MUST NOT 崩溃；MUST 记录日志；MAY 短熔断避免紧密重试

## MODIFIED Requirements

### Requirement: HTTP 未读校准 MUST 合并并发触发

The client SHALL coalesce concurrent HTTP unread calibration (`syncUcgUnreadFromServer` or equivalent) so that overlapping triggers within the same in-flight window share one round of `GET /conversations` (page 1) and one `GET /notifications/comments` (page 1). If additional sync requests arrive while that round is in flight, the client MUST run **one** follow-up calibration after the in-flight round completes so that later authority (e.g. mark-read) is not discarded by joining a stale in-flight Future alone.

当 `syncUcgUnreadFromServer` 因 App `resumed`、已读、消息刷新、进消息 Tab 等被并发触发时，客户端 MUST 合并为同一 in-flight 任务；若 in-flight 期间又有校准请求，完成后 MUST 再跑至多一轮补校准，MUST NOT 仅 await 旧 Future 导致已读后的权威结果丢失。

#### Scenario: Web 失焦再获焦不重复校准

- **WHEN** 用户在 Web 上先点击浏览器外部使应用失焦，再点击页面空白区域使应用 `resumed`
- **THEN** 未读 HTTP 校准 MUST 至多执行合理轮次（无未决脏标记时 1 轮；有未决时 1+1 补跑）
- **AND** MUST NOT 因链式回调无界叠加为大量相同接口请求

#### Scenario: 并发 sync 调用共享同一 Future

- **WHEN** 同一帧或短窗口内多处调用 `syncUcgUnreadFromServer` 且无后续未决
- **THEN** 实现 MUST 复用同一 in-flight Future
- **AND** 完成后所有调用方 MUST 观察到一致的未读计数结果

#### Scenario: in-flight 期间已读后补跑

- **WHEN** 一轮 `syncUcgUnreadFromServer` 正在进行
- **AND** 期间用户成功 `markConversationRead` 并再次请求校准
- **THEN** 客户端 MUST 在当前 in-flight 结束后再执行至少一轮 HTTP 校准
- **AND** `ucgUnreadCountProvider` MUST 反映已读后的服务端权威值（不为虚高乐观值）

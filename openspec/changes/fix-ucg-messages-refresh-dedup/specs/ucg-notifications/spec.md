## ADDED Requirements

### Requirement: HTTP 未读校准 MUST 合并并发触发
The client SHALL coalesce concurrent HTTP unread calibration (`syncUcgUnreadFromServer` or equivalent) so that overlapping triggers within the same in-flight window result in at most one round of `GET /conversations` (page 1) and one `GET /notifications/comments` (page 1).

当 `syncUcgUnreadFromServer`（或等价实现）因 App `resumed`、`accessToken` 刷新、WS 事件或 Shell 监听被**并发或链式**触发时，客户端 MUST 合并为同一 in-flight 任务；在任务完成前 MUST NOT 再次发起相同的首屏未读校准 HTTP。

#### Scenario: Web 失焦再获焦不重复校准
- **WHEN** 用户在 Web 上先点击浏览器外部使应用失焦，再点击页面空白区域使应用 `resumed`
- **THEN** 未读 HTTP 校准 MUST 至多执行 1 轮（会话首屏 + 互动通知首屏各 1 次）
- **AND** MUST NOT 因 `resumed` 与 `accessToken` 链式回调叠加为 3 次及以上相同接口请求

#### Scenario: 并发 sync 调用共享同一 Future
- **WHEN** 同一帧或短窗口内多处调用 `syncUcgUnreadFromServer`
- **THEN** 实现 MUST 复用同一 in-flight Future
- **AND** 完成后所有调用方 MUST 观察到一致的未读计数结果

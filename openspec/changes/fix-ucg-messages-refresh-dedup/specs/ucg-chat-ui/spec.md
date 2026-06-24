## ADDED Requirements

### Requirement: 消息 Tab 手动刷新 MUST NOT 重复请求首屏数据
The messages tab manual refresh actions (retry button and pull-to-refresh) SHALL fetch the conversation first page and comment-notification first page at most once each per user action.

用户在消息 Tab 点击「重试」或下拉刷新时，系统对 `GET /conversations?page=1` 与 `GET /notifications/comments?page=1`（或等价首屏接口）各 MUST 最多发起 **1 次** HTTP 请求；不得因 provider bump、Shell 监听或本地加载叠加导致同接口短时间重复请求。

#### Scenario: 错误页点击重试仅一轮请求
- **WHEN** 消息 Tab 处于加载失败错误态且用户点击「重试」
- **THEN** 客户端 MUST 各发起至多 1 次会话列表首屏请求与 1 次互动通知首屏请求
- **AND** MUST NOT 因 `bumpUcgNotificationsRefresh` 或 Shell 未读同步而额外重复相同接口

#### Scenario: 下拉刷新仅一轮请求
- **WHEN** 用户在消息 Tab 已加载列表上触发下拉刷新
- **THEN** 行为 MUST 与「重试」一致：每个首屏接口至多 1 次请求

#### Scenario: 刷新后未读角标仍正确
- **WHEN** 手动刷新成功完成
- **THEN** Shell 底部「消息」未读红点 MUST 仍反映会话未读与互动 `unreadCount` 的 OR 逻辑

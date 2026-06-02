## MODIFIED Requirements

### Requirement: Overlay navigation follows bootstrap completion

The system SHALL navigate and remove the startup overlay immediately after all required **local-only** cold-start bootstrap work completes, without an additional minimum display delay. 系统**必须**在冷启动所需**仅本地** bootstrap（含已登录用户的 catalog/history 磁盘 hydrate）全部完成后**立即**跳转并移除启动遮罩，**不得**再设置额外的最短展示等待（如固定 300ms）；**不得**将 history/catalog 远端同步或 logo 预热/下载纳入「bootstrap 完成」的前置条件。

#### Scenario: Navigate as soon as bootstrap finishes

- **WHEN** 本地 cold start bootstrap（`ColdStartBootstrap`、登录渠道 prefs 恢复、已登录时的 `loadFromDisk` hydrate）完成
- **THEN** 应用必须立即导航至目标路由并移除遮罩，且 MUST NOT 等待 history/event-options 网络或 logo precache/下载

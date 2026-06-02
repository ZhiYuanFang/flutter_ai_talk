## MODIFIED Requirements

### Requirement: Splash 仅本地门禁后进入主页

The system MUST navigate to `/home` (or login when unauthenticated) after local-only bootstrap without awaiting remote version check, baby profile fetch, history remote sync, event catalog remote sync, or event logo precache/download. Splash 启动流程**必须**在仅完成本地恢复与磁盘 hydrate 后进入 `/home`（未登录则按既有路由进入登录）；**不得**在 Splash 内 `await` 远程版本检查（`version/check`）、`loadBaby`（`user/get`）、`homeHistory.refreshFromRemote`、`eventCatalog.refreshFromRemote` / `bootstrap` 的网络部分，或 `EventLogoStartupWarmup.precacheCatalog` 作为进入主页的前置条件。

#### Scenario: 已登录弱网冷启动

- **WHEN** 用户已登录且网络不可用或极慢
- **THEN** Splash 在本地 session 恢复及 catalog/history 磁盘 hydrate（若可读）完成后必须进入 `/home`，且不得因 history、event/options 或 logo 下载/预热超时而一直停留在 Splash

#### Scenario: 本地恢复项

- **WHEN** Splash 执行启动逻辑
- **THEN** 允许阻塞的仅为：会话 token restore、登录渠道 prefs、本地已缓存的主题/宝宝性别（若有）、`eventCatalog.loadFromDisk()`、`homeHistory.loadFromDisk()`（及 hydrate 后必要的 `initialLoadDone` 标记）；`deviceNo` 网络 refresh、history/catalog 远端同步与 logo 文件下载/预热必须移至 `/home` 展示之后

#### Scenario: 有磁盘缓存时首帧非空

- **WHEN** 用户已登录且磁盘存在有效 catalog 或 history 快照
- **THEN** Splash MUST 在 `go(/home)` 前完成对应 `loadFromDisk`，使进主页首帧可展示磁盘中的目录与历史列表

### Requirement: 主页后台补全网络状态

The system SHALL run version check, baby profile fetch, deviceNo remote refresh, history/catalog remote sync, and event logo file downloads after the home shell is shown without blocking the initial route transition. 系统必须在展示主页壳子之后执行版本检查、宝宝信息拉取、`deviceNo` 远端 refresh、历史与事件目录远端同步及事件 logo 文件下载；这些任务**不得**阻塞从 Splash 到 `/home` 的路由跳转。

#### Scenario: 进主页后版本提示

- **WHEN** 用户已进入 `/home` 且版本检查发现新版本
- **THEN** 系统必须按既有 `maybeShowVersionPrompt` 规则展示提示（非强制更新可延迟，但不得回到 Splash 阻塞）

#### Scenario: 进主页后 catalog 与 logo 补全

- **WHEN** 用户已进入 `/home` 且已登录
- **THEN** 系统 MUST 在后台触发 `event/options` 对比刷新与 logo 文件下载，且不得要求用户再次经过 Splash 等待

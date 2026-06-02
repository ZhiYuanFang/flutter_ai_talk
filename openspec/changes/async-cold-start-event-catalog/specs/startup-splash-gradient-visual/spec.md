## MODIFIED Requirements

### Requirement: Cold start timing unchanged

The gradient and tagline styling MUST NOT add blocking work to `ColdStartBootstrap` or extend mandatory splash duration beyond local-only bootstrap. 渐变与标语样式 MUST NOT 在 `ColdStartBootstrap` 中增加新的阻塞任务；Splash 亦 MUST NOT 因渐变/标语而 `await` history/catalog 远端同步或事件 logo 预热/下载。

#### Scenario: Bootstrap order preserved

- **WHEN** 已登录用户冷启动
- **THEN** Splash MUST 在完成本地 session/主题恢复及 catalog/history 磁盘 hydrate 后立即 `go(/home)`；history/catalog 远端同步与 logo 文件下载 MUST 在主页展示之后异步执行

## REMOVED Requirements

### Requirement: Event logo precache during cold start

**Reason**: 阻塞式 ImageCache 预热导致新装与老用户 Splash 过长；logo 改由磁盘异步缓存 + `EventLogo` 本地文件展示，不再要求遮罩期间 precache。

**Migration**: 删除 `app.dart` 中对 `EventLogoStartupWarmup.precacheCatalog` 的 `await`；保留 `EventCatalogStore.mergeLocalLogoPaths` 与后台 `downloadLogo` 链路。可选在进主页后 unawaited 本地 FileImage precache，但不作为规范 MUST。

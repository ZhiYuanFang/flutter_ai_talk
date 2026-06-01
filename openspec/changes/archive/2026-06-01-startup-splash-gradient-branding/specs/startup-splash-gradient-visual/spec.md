## ADDED Requirements

### Requirement: Vertical gradient startup background

The Flutter cold-start branding overlay and the `/splash` placeholder screen SHALL use a full-screen vertical gradient background with a soft pink tone at the top and a soft cyan tone at the bottom, matching the product reference.

冷启动品牌遮罩与 `/splash` 占位页 MUST 使用全屏**自上而下**线性渐变背景：顶部为浅粉、底部为浅青（中部过渡为近白）；MUST NOT 再使用单一灰色 `#ECEFF1` 作为遮罩主背景。

#### Scenario: Overlay displays gradient

- **WHEN** 应用冷启动且 `StartupBrandingOverlay` 可见
- **THEN** 用户 MUST 看到铺满屏幕的竖向渐变背景（非纯色灰底）

#### Scenario: Splash route matches overlay

- **WHEN** 路由位于 `/splash` 且遮罩尚未淡出
- **THEN** 占位页背景 MUST 与遮罩渐变一致，避免明显色差闪烁

### Requirement: Blue tagline on startup

The startup tagline text SHALL remain「最懂你的胖宝」and SHALL be rendered in a fixed brand blue color that does not follow `ColorScheme.primary`.

标语 MUST 仍为「最懂你的胖宝」；MUST 使用**固定品牌蓝色**展示；MUST NOT 随当前 Material `primary` 主题色变化而改变标语颜色。

#### Scenario: Tagline color is brand blue

- **WHEN** 用户查看冷启动遮罩上的标语
- **THEN** 标语 MUST 为可读的中蓝色，与参考稿一致

#### Scenario: No decorative line under tagline

- **WHEN** 用户查看冷启动遮罩上的标语「最懂你的胖宝」
- **THEN** 标语下方 MUST NOT 显示下划线、分隔线或类似装饰横线

### Requirement: Logo layout unchanged

The system SHALL keep the centered splash logo asset and layout; only background and tagline styling change.

居中 `splash_logo` 资源与布局 MUST 保持不变；本变更仅调整背景与标语样式。

#### Scenario: Logo still centered

- **WHEN** 冷启动遮罩展示
- **THEN** Logo MUST 仍居中显示在标语上方，使用现有 `kSplashLogoAsset`

### Requirement: Cold start timing unchanged

The gradient and tagline styling MUST NOT add blocking work to `ColdStartBootstrap` or extend mandatory splash duration beyond existing behavior.

渐变与标语样式 MUST NOT 在 `ColdStartBootstrap` 中增加新的阻塞任务，亦 MUST NOT 延长既有最短展示/淡出规则。

#### Scenario: Bootstrap order preserved

- **WHEN** 已登录用户冷启动
- **THEN** 历史与事件目录 bootstrap 顺序 MUST 与变更前一致；logo 预热 MUST 在既有 catalog bootstrap 之后、`go(/home)` 之前执行

### Requirement: Event logo precache during cold start

The system SHALL merge valid on-disk logo paths into the in-memory event catalog after remote refresh, and SHALL precache event logos into Flutter `ImageCache` during the startup overlay before navigating to home.

系统 MUST 在冷启动遮罩期间、进入主页前，将事件 logo（优先本地文件，否则网络 URL）预热进 `ImageCache`；远端刷新后 MUST 合并仍有效的 `localLogoPath` 再写入内存 state。

#### Scenario: Precache before home

- **WHEN** 已登录用户冷启动且事件目录 bootstrap 完成
- **THEN** 系统 MUST 在离开启动遮罩前执行 logo 预热，且进入主页后 `EventLogo` SHOULD 优先命中已预热缓存

#### Scenario: Merge disk logo paths

- **WHEN** 远端目录与磁盘元数据不一致但 logo 文件未变
- **THEN** 返回给 UI 的目录项 MUST 保留对应 `localLogoPath`，避免无谓全网拉取

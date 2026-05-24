## ADDED Requirements

### Requirement: 原生启动窗口不得长时间纯白

The system SHALL use a branded native launch window background (color and/or logo) consistent with the app theme instead of a plain white screen until the first Flutter frame. 系统在 Flutter 首帧绘制前，原生启动窗口**不得**长时间呈现无品牌信息的纯白屏；必须使用与 App 主题一致的品牌色和/或 Logo（Android `LaunchTheme`、iOS LaunchScreen 等等价配置）。

#### Scenario: Android 冷启动

- **WHEN** 用户在 Android 上冷启动应用
- **THEN** 从点击图标到 Flutter 首帧之间，用户必须看到品牌色或 Logo 背景，而非默认纯白空窗

### Requirement: Flutter Splash 品牌连续

The system SHALL show a branded Flutter splash route that visually continues the native launch experience. Flutter `/splash` 路由必须使用与原生启动一致的视觉语言（背景色/Logo）；**不得**仅展示白底 Scaffold 加孤立转圈作为唯一品牌元素。

#### Scenario: 进入 Splash 路由

- **WHEN** 应用路由至 `/splash`
- **THEN** 页面必须展示品牌背景与可识别的应用标识（Logo 或应用名），转圈（若有）必须为次要元素

### Requirement: Splash 仅本地门禁后进入主页

The system MUST navigate to `/home` (or login when unauthenticated) after local-only bootstrap without awaiting remote version check or baby profile fetch. Splash 启动流程**必须**在仅完成本地恢复后进入 `/home`（未登录则按既有路由进入登录）；**不得**在 Splash 内 `await` 远程版本检查（`version/check`）或 `loadBaby`（`user/get`）作为进入主页的前置条件。

#### Scenario: 已登录弱网冷启动

- **WHEN** 用户已登录且网络不可用或极慢
- **THEN** Splash 在本地 session/deviceNo 恢复完成后必须进入 `/home`，且不得因版本或宝宝接口超时而一直停留在 Splash 转圈

#### Scenario: 本地恢复项

- **WHEN** Splash 执行启动逻辑
- **THEN** 允许阻塞的仅为：会话 token restore、本地 `deviceNo` 缓存、登录渠道 prefs、本地已缓存的主题/宝宝性别（若有）；其余任务必须移至 `/home` 之后

### Requirement: 主页后台补全网络状态

The system SHALL run version check, baby profile fetch, and history/catalog sync after the home shell is shown without blocking the initial route transition. 系统必须在展示主页壳子之后执行版本检查、宝宝信息拉取、历史与事件目录等网络同步；这些任务**不得**阻塞从 Splash 到 `/home` 的路由跳转。

#### Scenario: 进主页后版本提示

- **WHEN** 用户已进入 `/home` 且版本检查发现新版本
- **THEN** 系统必须按既有 `maybeShowVersionPrompt` 规则展示提示（非强制更新可延迟，但不得回到 Splash 阻塞）

## ADDED Requirements

### Requirement: Flutter overlay minimum display aligns with product splash duration

The Flutter full-screen startup branding overlay SHALL follow the same minimum display duration policy as the product splash (300ms floor, bootstrap may extend). Flutter 全屏品牌遮罩的最短展示策略**必须**与产品启动页一致：最短 **300ms**，本地 bootstrap 未完成时**不得**提前跳转。

#### Scenario: Overlay timing with home navigation

- **WHEN** the user is authenticated and cold start finishes local bootstrap
- **THEN** the app navigates to `/home` only after `max(bootstrap completion, 300ms)` and removes the overlay without animation

## MODIFIED Requirements

### Requirement: Flutter Splash 品牌连续

The system SHALL show a branded Flutter splash route that visually continues the native launch experience. Flutter `/splash` 路由或等价的启动遮罩**必须**使用与原生启动一致的视觉语言（背景色/Logo/标语）；**不得**仅展示白底 Scaffold 加孤立转圈作为唯一品牌元素；品牌元素**应为静态展示**，不依赖动画传达品牌信息。

#### Scenario: 进入 Splash 路由

- **WHEN** 应用路由至 `/splash` 或展示等效启动遮罩
- **THEN** 页面必须展示品牌背景与可识别的应用标识（Logo 或应用名）及静态标语（若已配置），转圈（若有）必须为次要元素

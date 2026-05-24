## ADDED Requirements

### Requirement: Flutter startup overlay is static branding

The cold-start Flutter branding overlay SHALL display a static logo and static tagline without pulse, scale, glow, or reveal animations. 冷启动 Flutter 品牌遮罩**必须**展示静态 Logo 与静态标语，**不得**使用心跳缩放、光晕、标语 Reveal 等动画作为品牌展示手段。

#### Scenario: No motion on overlay

- **WHEN** `StartupBrandingOverlay` is visible during cold start
- **THEN** the logo and tagline remain visually static with no repeating or one-shot animation controllers driving their appearance

### Requirement: Overlay navigation follows bootstrap completion

The system SHALL navigate and remove the startup overlay immediately after all required cold-start bootstrap work completes, without an additional minimum display delay. 系统**必须**在冷启动所需 bootstrap 全部完成后**立即**跳转并移除启动遮罩，**不得**再设置额外的最短展示等待（如固定 300ms）。

#### Scenario: Navigate as soon as bootstrap finishes

- **WHEN** cold start bootstrap (including logged-in history and event catalog bootstrap when applicable) completes
- **THEN** the app navigates to the target route and removes the overlay without waiting for a minimum display timer

## REMOVED Requirements

### Requirement: Minimum overlay display is 300 milliseconds

**Reason**: 产品要求去掉固定最短停留，准备工作完成即跳转。

**Migration**: 删除 `kMinStartupBrandingDisplay` 及 `app.dart` 中与之并行的 `Future.delayed`。

### Requirement: Overlay removes without fade animation

The system SHALL remove the startup overlay immediately after navigation preconditions are met, without an opacity fade-out animation. 满足跳转与最短展示条件后，系统**必须**立即移除启动遮罩，**不得**再执行淡出动画（如原 `kStartupBrandingFadeOut` / `AnimatedOpacity`）。

#### Scenario: Instant overlay dismiss

- **WHEN** cold start is ready to show the target route (`/home` or login)
- **THEN** the overlay is removed in the same frame transition without a timed fade-out

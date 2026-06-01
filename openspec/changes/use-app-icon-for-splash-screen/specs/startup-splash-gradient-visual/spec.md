# Spec Delta: startup-splash-gradient-visual

## MODIFIED Requirements

### Requirement: Logo layout unchanged

The system SHALL keep the centered startup icon layout, but MUST switch the icon source to the same master asset as the desktop app icon and render it as a circle-filled image.

冷启动遮罩与 `/splash` 占位页的中心图标布局必须保持居中，但图标资源必须改为与桌面 App 图标同源资产；图标必须以圆形裁剪并填满容器（例如 `BoxFit.cover`），不得出现明显内缩留白或非圆形外观。

#### Scenario: Overlay uses desktop icon source

- **WHEN** 应用冷启动且 `StartupBrandingOverlay` 可见
- **THEN** 中心图标必须使用桌面图标同源资产，而不是独立 `splash_logo` 资源

#### Scenario: Overlay icon is circle-filled

- **WHEN** 用户查看冷启动遮罩中心图标
- **THEN** 图标必须呈现圆形且内容填满圆形容器，不得出现明显空白边框

#### Scenario: Splash placeholder matches overlay icon style

- **WHEN** 路由位于 `/splash` 且遮罩尚未淡出
- **THEN** 占位页中心图标必须与遮罩使用同一图标来源与同等圆形填满样式，避免视觉跳变

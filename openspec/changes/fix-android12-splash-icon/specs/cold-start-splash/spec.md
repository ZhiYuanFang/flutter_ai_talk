## ADDED Requirements

### Requirement: Android 12+ 原生启动窗口图标 MUST 与 Flutter 品牌连续
The native launch window on Android 12+ SHALL present a splash icon that visually continues into the Flutter cold-start branding overlay without jarring shape changes.

在 API 31 及以上，从点击应用图标到 Flutter 首帧之间，原生启动窗口除渐变背景外，若展示中心图标，该图标 MUST 与后续 Flutter 冷启动遮罩使用同源品牌资产且形状一致（圆形填满），不得因系统 SplashScreen API 默认裁剪而出现与 Flutter 圆形图标明显不一致的方形容器外观。

#### Scenario: Android 12+ 冷启动无图标形状跳变
- **WHEN** 用户在 Android 12 及以上设备冷启动应用并观察原生 Splash 至 Flutter 遮罩的过渡
- **THEN** 中心图标 MUST NOT 从圆角正方形突变为圆形（或反之）
- **AND** 渐变背景 MUST 保持品牌连续

#### Scenario: API 30 及以下行为不变
- **WHEN** 用户在 Android 11 及以下设备冷启动应用
- **THEN** 原生启动窗口 MUST 继续使用 `launch_background.xml` layer-list 展示渐变与居中图标
- **AND** MUST NOT 因本变更而退化或移除品牌展示

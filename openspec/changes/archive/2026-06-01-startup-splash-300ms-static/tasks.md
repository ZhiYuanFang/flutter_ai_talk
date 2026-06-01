## 1. 常量与时序

- [x] 1.1 将 `kMinStartupBrandingDisplay` 改为 `Duration(milliseconds: 300)`（`startup_branding.dart`）
- [x] 1.2 删除 `kStartupBrandingFadeOut`、`kStartupTaglineRevealDuration` 等仅用于动画的常量
- [x] 1.3 在 `app.dart` 去掉 `_overlayOpacity` 与淡出 `Future.delayed`；bootstrap 完成后直接 `setState(() => _showStartupOverlay = false)`

## 2. 静态启动遮罩

- [x] 2.1 重写 `StartupBrandingOverlay`：静态 `Image.asset` Logo + 静态 `Text` 标语（终态样式：约 21sp / w700 / primary）
- [x] 2.2 删除 `SplashLogoPulse` 类及心跳 `AnimationController`
- [x] 2.3 删除 `startup_tagline_reveal.dart` 并清理所有 import 引用

## 3. 验证

- [x] 3.1 未登录冷启动：遮罩约 300ms 后进入登录/主页，无 Logo/标语动画、无淡出
- [x] 3.2 已登录冷启动：若 history/catalog bootstrap > 300ms，遮罩保持至 bootstrap 完成再跳转；Logo/标语始终静态
- [x] 3.3 确认无 lint 报错，无残留对已删 Widget/常量的引用

## 4. 去掉最短展示等待（产品调整）

- [x] 4.1 删除 `kMinStartupBrandingDisplay` 及 `app.dart` 中 `Future.delayed` 并行等待
- [x] 4.2 冷启动全部 bootstrap 完成后立即 `go` 并移除遮罩，无额外最短停留时间
- [x] 4.3 确认无残留对 `kMinStartupBrandingDisplay` 的引用

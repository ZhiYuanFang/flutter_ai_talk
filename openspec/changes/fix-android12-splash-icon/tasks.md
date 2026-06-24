## 1. Android 12+ Splash 专用图标资源（`startup-splash-gradient-visual`）

- [x] 1.1 新增 `drawable/splash_screen_icon.xml`：以 `<inset android:inset="18%">` 包裹 `@drawable/app_icon_round`，使内容落在系统安全区内
- [x] 1.2 在 `values/colors.xml` 新增 `splash_icon_background`（`#F7F8FA`，与 `launch_gradient` 中间色一致）
- [x] 1.3 更新 `values-v31/styles.xml`：`windowSplashScreenAnimatedIcon` → `@drawable/splash_screen_icon`；`windowSplashScreenIconBackgroundColor` → `@color/splash_icon_background`

## 2. 回归与兼容（`cold-start-splash`）

- [x] 2.1 确认 `values/styles.xml` 与 `launch_background.xml` 未改动，API 30 及以下路径不变
- [x] 2.2 确认 `MainActivity.installSplashScreen` 与 `hideNativeSplash` 时序未改动

## 3. 验证

- [ ] 3.1 Android 14 真机冷启动：原生 Splash 图标为圆形，无圆角正方形容器
- [ ] 3.2 Android 14 真机：原生 Splash → Flutter `StartupBrandingOverlay` 过渡无明显图标形状跳变
- [ ] 3.3 Android 11 或模拟器 API 30：冷启动仍通过 layer-list 正常展示渐变与图标
- [ ] 3.4 渐变背景在原生与 Flutter 遮罩间无色差闪烁

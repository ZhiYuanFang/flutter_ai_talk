## Context

项目冷启动分两段：

1. **原生 Splash**（`LaunchTheme` + `installSplashScreen` + `KeepNativeSplash`）— Android 12+ 走 `Theme.SplashScreen`（`values-v31/styles.xml`）。
2. **Flutter 遮罩**（`StartupBrandingOverlay`）— `ClipOval` + `app_icon_round.png`，渐变与原生一致。

API 30 及以下仍用 `windowBackground` → `launch_background.xml`（layer-list 176dp 居中图标），行为正常。

Android 12+ SplashScreen API 约束：

- `windowSplashScreenAnimatedIcon` 会被系统施加**不可禁用**的圆形或 squircle 遮罩。
- 图标画布逻辑尺寸 288×288 dp，有效内容应落在中心直径约 192 dp（2/3）安全区内。
- `windowSplashScreenIconBackgroundColor` 在部分 OEM 上仍可见，应匹配背景渐变中间色以减少「方块底板」感。

当前问题：`app_icon_round.png` 作为全幅方形位图直接提交给系统，在 vivo Android 14 等机型上被裁成圆角正方形，与 Flutter 圆形图标跳变。

约束：遵循 `v2.0.2` 基线；图标仍与桌面同源（`app_icon_round`）；不延长冷启动阻塞时间。

## Goals / Non-Goals

**Goals:**

- Android 12+ 原生 Splash 阶段展示与 Flutter `StartupBrandingIcon` 视觉一致的圆形品牌图标。
- 原生渐变背景保持与 `launch_gradient` / Flutter `kStartupPageGradient` 一致。
- API 30 及以下行为不变。

**Non-Goals:**

- 修改桌面 adaptive icon（`ic_launcher`）。
- 移除原生 Splash 图标、改为仅渐变（方案 1）。
- 改动 iOS LaunchScreen。
- 调整 `ColdStartBootstrap` 时序或 `startup-splash-static-300ms` 行为。

## Decisions

### 1. 专用 `splash_screen_icon` inset drawable

新增 `drawable/splash_screen_icon.xml`，用 `<inset>` 包裹 `@drawable/app_icon_round`：

```xml
<inset xmlns:android="http://schemas.android.com/apk/res/android"
    android:drawable="@drawable/app_icon_round"
    android:inset="18%" />
```

约 18% inset 使 64% 内容区落在系统 66% 安全区内，圆形位图在系统遮罩下更接近满圆填充，减少方形容器边缘外露。

**备选**：直接继续用 `app_icon_round` → 已在 Android 14 验证失败。

**备选**：全新矢量重绘 → 成本高，且偏离「桌面图标同源」；inset 复用现有 PNG 即可。

### 2. 图标底板色对齐渐变中间色

在 `values/colors.xml` 新增：

```xml
<color name="splash_icon_background">#F7F8FA</color>
```

`values-v31/styles.xml` 设置：

```xml
<item name="windowSplashScreenIconBackgroundColor">@color/splash_icon_background</item>
```

与 `launch_gradient` 中心色 `#F7F8FA` 及 Flutter 渐变 stops 中间段一致，系统若绘制 icon background 时与渐变背景无缝融合。

### 3. 仅改 `values-v31`，不动 API 30 路径

`values/styles.xml` 与 `launch_background.xml` 保持现状，避免回退旧设备体验。

`windowSplashScreenBackground` 继续使用 `@drawable/launch_gradient`（已在 v31 使用）。

### 4. 不引入新依赖

已有 `androidx.core:core-splashscreen:1.0.1` 与 `installSplashScreen()`，无需升级。

### 5. Flutter 层零改动

`StartupBrandingIcon` 已满足圆形填满；原生修复后两段视觉应对齐，无需改 Dart。

## Risks / Trade-offs

- **[Risk] inset 比例在不同 OEM 上仍略有差异** → 以 Android 14 vivo 真机为验收基准；必要时微调 inset 至 16%–20%。
- **[Risk] 部分 ROM 仍用 squircle 而非正圆** → iconBackground 融色 + 安全区 inset 减轻方角感；无法完全控制系统遮罩形状。
- **[Risk] `launch_gradient` 作 splash background 在极少数机型渲染异常** → 本次不改为纯色；若回归可单独评估 `splash_icon_background` 作 fallback。

## Migration Plan

纯 Android 资源与主题变更，无数据迁移。发布后即生效；回滚为还原 `values-v31/styles.xml` 并删除 `splash_screen_icon.xml`。

## Open Questions

- inset 18% 是否需在 hdpi/xxxhdpi 分别验证？（inset 百分比应跨密度一致，预计无需分密度资源。）

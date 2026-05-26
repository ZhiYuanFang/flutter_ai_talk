## Context

- **现状**：`StartupBrandingOverlay` 使用 `kSplashBackgroundColor`（`#ECEFF1`）纯色；标语 `color: Theme.of(context).colorScheme.primary`（随宝宝性别主题变化）。冷启动时序由 `PangbaoApp._runColdStart` + `StartupBrandingOverlay` 控制，不在此变更中调整。
- **参考稿**：纵向渐变（上粉、下浅青/蓝绿）、居中气泡 Logo、蓝色「最懂你的胖宝」。
- **原生**：Android `launch_brand` 为 `#ECEFF1` 纯色 + 居中 `splash_logo` bitmap。

## Goals / Non-Goals

**Goals:**

- Flutter 遮罩与参考图一致的**竖向渐变**与**蓝色标语**。
- 遮罩与 `/splash` 占位页背景一致，减少路由切换闪烁。
- 常量集中定义，便于与 Android 资源对齐。

**Non-Goals:**

- 不修改 `ColdStartBootstrap`、`kMinStartupBrandingDisplay`、事件目录/历史 bootstrap 顺序。
- 不强制实现标语 1.5s 动画（当前实现若为静态则保持）。
- iOS 原生 LaunchScreen 大改（若存在仅尽量接近中位色）。

## Decisions

1. **渐变色（Flutter）**  
   在 `startup_branding.dart` 定义三色 stops，例如：
   - top: `#F8D4E0`（浅粉）
   - middle: `#F7F8FA`（近白）
   - bottom: `#D4EFF5`（浅青）  
   使用 `BoxDecoration` + `LinearGradient`（`begin: topCenter`, `end: bottomCenter`）。具体色值实现时可按设计稿微调，但须保持「上暖粉、下冷青」关系。

2. **标语颜色**  
   **决定**：固定 `kStartupTaglineColor`（建议 `#2B6CB0` 或 `#1E6BB8` 一类中蓝），**不再**绑定 `ColorScheme.primary`。  
   **理由**：参考稿为品牌蓝；启动遮罩展示时主题可能仍为默认性别色，用 primary 会导致标语发灰或发红。

3. **组件改动**  
   `StartupBrandingOverlay`：`ColoredBox` → `DecoratedBox(gradient)`；`Text` 使用 `kStartupTaglineColor`。  
   `SplashScreen`：同样 `DecoratedBox` 或 `Container(decoration: ...)` 铺满。

4. **Android 原生衔接**  
   **决定**：新增 `res/drawable/launch_gradient.xml`（`gradient` shape 竖向）替代 `launch_background` 底层纯色；`launch_brand` 可保留为中位色 fallback；API 31 `windowSplashScreenBackground` 指向渐变 drawable 或中位色。  
   **备选**：仅改 `launch_brand` 为中位色 — 实现快但过渡仍弱；优先简易渐变 drawable。

5. **状态栏**  
   浅色渐变背景下状态栏图标使用**深色**（`SystemUiOverlayStyle.dark`）仅在启动遮罩显示时设置 — 可选，若当前已可读则最小改动。

## Risks / Trade-offs

- **[Risk] 渐变与主题色无关** → 启动页本即为品牌固定屏，可接受。  
- **[Risk] Android 旧机型 gradient drawable 差异** → 保留 `@color/launch_brand` fallback。  
- **[Risk] 与深色全局主题反差** → 遮罩独立视觉，淡出后进入 App 主题，已有预期。

## Migration Plan

1. 更新 Flutter 常量与两个 Widget。  
2. 可选更新 Android drawable。  
3. 真机冷启动目视：原生 → Flutter 遮罩 → 主页，无灰闪。  
4. `dart analyze` 相关文件。

## Open Questions

- 标语是否需要恢复/新增 1.5s reveal 动画（**默认否**，本变更仅配色）。

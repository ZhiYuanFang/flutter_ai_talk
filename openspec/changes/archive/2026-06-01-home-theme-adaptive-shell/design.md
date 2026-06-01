## Context

当前 `buildAppTheme`（`app_theme_scope.dart`）仅构建 **浅色 Material3**：`customBackground` 直接赋给 `scaffoldBackgroundColor`，性别决定 `ColorScheme.primary`；`themePrimaryBlend` 用于 AppBar/Card。设置页 `MaterialColorPicker` 提供若干浅色块 + 纯黑 `#000000`，无语义分层（shell / surface / pill）。

主页组件（今日摘要、历史日标题、时间轴 tile、按钮网格）混用 `ColorScheme`、`themePrimaryBlend` 与事件 `color`，圆角与阴影多为硬编码，无法呈现参考 baby-tracker 的深色外壳 + 卡片 + 药丸 + 底部 elevated 面板效果。

**约束**：历史 WebSocket 推送、事件目录、语音/文字/按钮输入模式逻辑不变；Phase 1 仅主题令牌 + 设置预设 + 主页视觉。

## Goals / Non-Goals

**Goals:**

- 引入 `AppVisualTokens` `ThemeExtension`，统一 shell / surface / pill / panel / shadow 语义。
- 支持**主题自适应深色 shell**：用户种子色经 HSL 推导外壳色，非固定 `#1A1C24`；「夜空」预设提供参考 bundle（shell `#1A1C24`）。
- 设置页增加预设（含「夜空」），合并废弃纯黑块；经典浅色仍为默认。
- 主页 Phase 1 组件改用 tokens，升级今日 pill、日卡片、时间轴 tile、按钮网格容器样式。
- 浅色模式保留性别 primary accent；深色 shell 下 chip/强调以用户种子与事件色为主。

**Non-Goals:**

- Phase 2：趋势页、登录页、历史详情全站深色适配。
- 独立 3D 图标资源（继续 `EventLogo`，可增强槽位阴影）。
- 改动 WS 协议、事件 catalog API、输入模式状态机。
- 动态主题随系统明暗切换（仅随用户背景/预设）。

## Decisions

### 1. `AppVisualTokens` 作为唯一视觉语义源

**决定**：新增 `AppVisualTokens extends ThemeExtension<AppVisualTokens>`，字段示例：

| 字段 | 用途 |
|------|------|
| `shellColor` | 全页最外层背景（Scaffold） |
| `surfaceColor` | 卡片、日块、底部输入 panel 底色 |
| `surfaceBorderColor` | 卡片/面板描边（可选低 alpha） |
| `pillBackground` / `pillBorder` | 今日摘要 chip |
| `onShell` / `onSurface` | 主/次文本（或委托 `ColorScheme`） |
| `panelShadow` | 底部网格/ dock elevation |
| `isDarkShell` | 分支开关（组件可读） |

**理由**：避免各 widget 重复 `computeLuminance()`；与 Material `ColorScheme` 并存——`ColorScheme` 仍管 M3 组件，`AppVisualTokens` 管产品 shell 层次。

**替代方案**：仅用 `ThemeData.brightness` —— 不足以表达「浅色 accent + 深色 shell」或用户种子推导差异。

### 2. 预设 bundle 优先，再 HSL 推导（C → A）

**决定**：

1. **`ThemePreset` 枚举**（`classicLight`、`nightSky`、及现有 Material 浅色块映射为 `softBlue` 等）定义固定 bundle：`seedColor`、`shellColor`、`surfaceColor`、`isDarkShell`。
2. **`nightSky`**：`seedColor = Color(0xFF1A1C24)`，`shellColor` 同值，`surfaceColor` 略提亮（HSL L+6~8%），`isDarkShell = true`。
3. **自定义色**：用户从 picker 选色 → 存 `custom_bg_color`；若 `luminance < 0.25` 或用户曾选 `#000000`，走 **HSL 推导**：以 seed 的 H/S 固定，L 钳制在 shell 区间，surface = shell L+Δ，pill = surface L+Δ2。
4. **默认**：无持久化色 → `classicLight`（现有性别 blend 白底逻辑）。

**理由**：预设保证「夜空」与参考 UI 一致；自定义色仍个性化，不绑死 `#1A1C24`。

**纯黑迁移**：移除 picker 中 `#000000` 独立块；若本地已存 `0xFF000000`，启动时映射为 `nightSky` bundle（一次性写回新 seed `#1A1C24`），settings 展示为「夜空」选中态。

### 3. 持久化：颜色值 + 可选 preset id

**决定**：保留 `custom_bg_color`（int）；新增可选 `theme_preset_id`（string，如 `night_sky`）。应用 preset 时**同时**写入 seed 色与 preset id；自定义 picker 清除 preset id。`loadCustomBackground` 扩展为 `loadThemePreferences()` 返回 `{Color? seed, ThemePreset? preset}`。

**理由**：最小破坏冷启动路径；preset id 便于 UI 高亮「夜空」而非仅比对 RGB。

### 4. `buildAppTheme` 分支

**决定**：

```text
resolveThemeBundle(sex, seed, preset?) → VisualBundle
buildAppTheme → ThemeData(
  colorScheme: isDarkShell
    ? ColorScheme.fromSeed(seed: accentSeed, brightness: dark).copyWith(surface: surfaceColor)
    : ColorScheme.fromSeed(seed: sexPrimary, brightness: light),
  scaffoldBackgroundColor: shellColor,
  extensions: [tokens, ...],
)
```

- 浅色：`accentSeed = sexPrimary`（现状）。
- 深色 shell：`accentSeed = user seed`（或 preset seed）；`primary` 可用于链接/少量 M3 控件，chip 强调优先 `resolveEventColor`。

**AppBar**：深色 shell 下 `appBarTheme.backgroundColor = shellColor` 或略提亮 surface，前景 `onShell`。

### 5. 主页组件改造范围

| 组件 | 改动 |
|------|------|
| `HomeTodaySummaryPanel` | chip → StadiumBorder + pill tokens；容器 optional surface 圆角 |
| `HomeHistoryDateHeader` | 背景 `surfaceColor`，文字 `onSurface` |
| `HomeHistoryScroll` / 日卡片 | 外层 `DecoratedBox` surface + 圆角 12–16 |
| `HomeHistoryTimelineTile` | rowHeight 可略增（36–38）；logo 槽 `BoxDecoration` 阴影；点/线色仍 event color |
| `HomeButtonEventGrid` | 外层 panel：`surfaceColor` + `panelShadow`；cell 圆角底 |
| `HomeInputModeDock` | 与按钮 panel 视觉统一，不改动模式切换逻辑 |
| `home_screen.dart` | Scaffold 背景读 `shellColor` |

**不改动**：WS 订阅、`eventCatalogProvider`、输入 channel、add/send 流程。

### 6. 设置页 UI

**决定**：「主题」区改为 **预设横滑/网格**（经典、夜空、原有浅色块）+「更多颜色」打开完整 picker。选中态描边；「清除自定义」恢复 `classicLight`。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| HSL 推导对某些 seed 对比度不足 | 对 `onShell`/`onSurface` 用 WCAG 启发式：L 差不足时强制用白/黑 87% |
| 仅主页深色、设置页/AppBar 仍浅色感不一致 | Phase 1 至少 AppBar + 主页统一 shell；设置页 body 可仍 ListView 白卡片（或轻量 surface） |
| `#000000` 迁移改变老用户外观 | 映射到夜空（设计意图）；proposal 已说明 |
| ThemeExtension 遗漏 copyWith/lerp | 实现完整 `copyWith`/`lerp` 以满足 Flutter 规范 |
| 与 `themePrimaryBlend` 并存混淆 | 深色 shell 下 `themePrimaryBlend` 改为 blend on `surfaceColor` 或标记 `@Deprecated` 并内联到 tokens |

## Migration Plan

1.  ship tokens + `buildAppTheme` 分支（默认行为与现网浅色一致）。
2.  启动读 prefs：`0xFF000000` → 写 `night_sky` + `#1A1C24`。
3.  设置页新 UI；用户可随时「清除自定义」回经典。
4.  主页 widget 逐文件切 tokens；无后端变更。
5.  **回滚**：feature 可单 PR revert；prefs 新 key 忽略即可恢复旧逻辑。

## Open Questions

- （已决）默认保持经典浅色；夜空可选。
- （已决）Phase 2 再覆盖 trends/login。
- 日卡片圆角 12 vs 16：实现时以参考稿为准，spec 留 token `surfaceRadius`。

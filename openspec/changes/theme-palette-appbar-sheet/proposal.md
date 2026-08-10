## Why

主题切换埋在设置页，主壳三页改色路径长。需要在喂养 / 预测 / UCG 标题栏最右侧固定调色盘入口，底部共用一张 Sheet 改主题色与自动夜空，并从设置移除主题区块以免双入口。

## What Changes

- 主壳三页标题栏最右侧增加调色盘按钮；喂养页趋势保留在其左侧。
- 抽出**唯一**公用主题调色 Sheet（经典 / 夜空 / 彩色 + 色盘默认展示 + 自动夜空开关）；三页只挂入口，不复制 Sheet。
- 用户在色盘改自定义色时，MUST 自动选中「彩色」并持久化为自定义浅色基线。
- 自动夜空开启时不得提供可用的自定义选色（与现 `theme-settings-presets` 一致；开关仍在 Sheet 内）。
- **BREAKING（设置 UI）**：设置页移除「主题」区块（预设 swatch + 自动夜空行）；调度/持久化能力仍保留，入口改到 Sheet。

## Capabilities

### New Capabilities

- `theme-palette-appbar-sheet`：主壳调色盘入口与公用主题 Sheet 行为。

### Modified Capabilities

- `app-theme-customization`：主题控件从设置页迁到公用 Sheet；色盘默认展示；改色自动选中彩色；设置页不再承载主题区块。

## Impact

- 新：`theme_palette_sheet.dart`、`ThemePaletteIconButton`（或等价）。
- 改：`home_immersive_header.dart`、`smart_prediction_screen.dart` 顶栏、UCG 主壳可见顶栏、`settings_screen.dart` 删除主题段。
- 复用：`persistThemePreferences` / `themeScheduleEnabledProvider` / `refreshScheduledTheme` / widget sync。

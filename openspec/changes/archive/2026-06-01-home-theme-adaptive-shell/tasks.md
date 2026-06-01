## 1. AppVisualTokens 与主题 bundle

- [x] 1.1 新增 `app_visual_tokens.dart`：`AppVisualTokens` ThemeExtension（shell/surface/pill/panel/shadow/isDarkShell/onShell/onSurface），完整 `copyWith` + `lerp`
- [x] 1.2 新增 `theme_preset.dart`（或同级）：`ThemePreset` 枚举、`classicLight` / `nightSky` 及现有浅色块 bundle 定义
- [x] 1.3 实现 `resolveVisualBundle(sex, seed, preset?)`：HSL 深色推导、luminance 阈值、`onShell`/`onSurface` 对比度兜底
- [x] 1.4 扩展 `buildAppTheme`：挂载 extensions、dark/light `ColorScheme` 分支、`scaffoldBackgroundColor = shellColor`
- [x] 1.5 调整 `themePrimaryBlend`：深色 shell 下基于 `surfaceColor` blend，或内联至 tokens 调用点

## 2. 持久化与冷启动

- [x] 2.1 扩展 `custom_background_persist.dart`：`theme_preset_id` 读写、`loadThemePreferences()` / `persistThemePreferences()`
- [x] 2.2 冷启动：`cold_start_bootstrap.dart` / `app.dart` 读取 bundle；`#000000` → 夜空迁移写回
- [x] 2.3 `customBackgroundProvider` 或新 provider 暴露当前 preset + seed，供设置页与 `buildAppTheme` 使用

## 3. 设置页主题预设 UI

- [x] 3.1 重构「主题」区：预设网格（经典默认、夜空、原有浅色块）+ 选中态 +「更多颜色」入口
- [x] 3.2 实现夜空点击：应用 bundle、持久化 preset id + `#1A1C24` seed
- [x] 3.3 移除 `MaterialColorPicker` 中独立 `#000000` 块；清除自定义恢复 classic light
- [x] 3.4 preset 与自定义互斥：picker 选色清 preset id；选 preset 覆盖自定义色

## 4. 主页 shell 与今日摘要

- [x] 4.1 `home_screen.dart`：Scaffold / 最外层背景读 `tokens.shellColor`；AppBar 随深色 shell 调整
- [x] 4.2 `home_today_summary_panel.dart`：chip 改 Stadium + `pillBackground`/`pillBorder`；保留折叠/展开与事件色

## 5. 历史列表与日卡片

- [x] 5.1 `home_history_scroll.dart`（及日块容器）：surface 圆角卡片包裹按日记录
- [x] 5.2 `home_history_date_header.dart`：背景/文字改用 surface/onSurface tokens
- [x] 5.3 `home_history_timeline_tile.dart`：行高/字号区间、EventLogo 槽 shadow/padding；不改 tap/stop/WS 逻辑

## 6. 底部输入区与按钮网格

- [x] 6.1 `home_button_event_grid.dart`：外层 elevated panel（`surfaceColor` + `panelShadow`）；cell 圆角底
- [x] 6.2 `home_input_mode_dock.dart`：与 panel tokens 视觉统一；三模式切换逻辑不变

## 7. 验证（手工）

- [x] 7.1 默认经典浅色：新装/清除自定义后主页与升级前观感一致
- [x] 7.2 夜空预设：shell `#1A1C24`、冷启动恢复、设置选中态正确
- [x] 7.3 老用户 `#000000` 迁移为夜空；picker 无独立纯黑块
- [x] 7.4 自定义深色种子：HSL 推导 shell 非固定 hex；浅色种子仍 light bundle
- [x] 7.5 主页：今日 pill、日卡片、时间轴、按钮 grid、dock 层次正确；语音/文字/按钮 + WS 历史推送行为不变

## 1. 持久化与调度（app-theme-schedule）

- [x] 1.1 `custom_background_persist.dart`：`ThemePreferences` 增加 `scheduleEnabled`；键 `theme_schedule_enabled` 读写，缺省 `true`；`persistThemePreferences` / `loadThemePreferences` / `clearThemePreferences` 对齐
- [x] 1.2 `app_theme_scope.dart`：新增 `themeScheduleEnabledProvider`；`effectiveThemeProvider` watch 并传入 `resolveDisplay`
- [x] 1.3 `app_theme_schedule.dart`：`resolveDisplay` 增加 `scheduleEnabled` 参数；仅 enabled 且在 19:00–05:00 时强制夜空
- [x] 1.4 `applyUserThemeBaseline`：冷启动加载 `scheduleEnabled` 到 provider

## 2. 设置页 UI（app-theme-customization）

- [x] 2.1 `settings_screen.dart`：「主题」标题行改为 `Row`，右侧「自动夜空」+ `Switch`，绑定 provider 与持久化
- [x] 2.2 `_ThemePresetSection` 改为 Stateful：`scheduleEnabled==true` 时仅经典/夜空；`false` 时增加彩色 swatch
- [x] 2.3 彩色 swatch：无 seed 用渐变/图标，有 seed 显示实色；点击 toggle `_colorWheelExpanded`；点经典/夜空收起色盘
- [x] 2.4 移除「自定义背景色」常显标题与「清除自定义背景」ListTile；色盘仅在 expanded 且 schedule off 时渲染
- [x] 2.5 切换自动夜空 ON 时强制 `expanded=false` 并 `refreshScheduledTheme`

## 3. 回归验证

- [x] 3.1 自动夜空 ON（默认）：晚间强制夜空；设置页无彩色/色盘；白天自定义基线仍展示
- [x] 3.2 自动夜空 OFF：全天跟基线；彩色 toggle 展开/收起；选色持久化
- [x] 3.3 点「经典」清除自定义 seed；设置页无「清除自定义背景」入口
- [x] 3.4 `flutter analyze` 无新增 error

## Why

`theme-schedule-ucg-visual-polish` 引入 19:00–05:00 自动夜空后，用户在晚间设置自定义背景色时界面仍为夜空，易被误解为「选色无效」。需在设置页提供可关闭的「自动夜空」开关（默认开启），并重构自定义色入口为折叠色盘；同时移除已不再需要的「清除自定义背景」操作。

## What Changes

- 设置页「主题」标题行右侧增加 **自动夜空** Switch（默认 **开**）；持久化 `theme_schedule_enabled`。
- **自动夜空开**：仅展示「经典」「夜空」两个 swatch；隐藏彩色块与 HSV 色盘；用户不可修改自定义色（已持久化的自定义基线在 05:00–19:00 仍正常展示，晚间仍按调度覆盖为夜空）。
- **自动夜空关**：展示「经典」「夜空」「彩色」三 swatch；色盘 **默认收起**，点击彩色块展开/再点收起；选色即时持久化并生效。
- 删除设置页 **「清除自定义背景」** ListTile；恢复经典须通过点击「经典」swatch。
- 修改 `AppThemeSchedule.resolveDisplay`：仅当 `theme_schedule_enabled == true` 且在 19:00–05:00 窗口时强制夜空；关闭调度后始终应用用户基线。

## Capabilities

### New Capabilities

（无——行为扩展落在既有主题能力 delta 内。）

### Modified Capabilities

- `app-theme-schedule`：增加用户可关闭定时调度（默认开启）；关闭后不再按时间强制夜空。
- `app-theme-customization`：设置页布局（标题行 Switch、折叠色盘、schedule 开时禁用自定义入口）；移除「清除自定义背景」入口。

## Impact

| 区域 | 路径 |
|------|------|
| 调度 | `app/lib/theme/app_theme_schedule.dart` |
| 持久化 | `app/lib/theme/custom_background_persist.dart` |
| Provider | `app/lib/theme/app_theme_scope.dart` |
| 设置 UI | `app/lib/ui/settings_screen.dart` |
| 色盘组件 | `app/lib/theme/theme_custom_color_wheel.dart`（复用，布局由 settings 控制） |

与 `theme-schedule-ucg-visual-polish` 为增量关系；撤销其 design 中「不提供关闭定时夜空开关」的 Non-Goal。

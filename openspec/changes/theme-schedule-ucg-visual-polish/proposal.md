## Why

产品需要在保留「经典」「夜空」快捷主题的前提下，支持任意自定义背景色，并按本地时间 19:00–05:00 自动切换夜空（逻辑统一、不设例外）。同时夜空主题下 UCG 模块存在浅色卡片配白色正文导致不可读；女性经典色需调整为玫瑰红；主页今/昨小时趋势图需由平滑曲线改为折线。与 `ucg-compose-bg-upload-publish-theme` 中已规划的定时主题、新帖发表后导航互补：本变更补齐主题定制 UI、对比度 token、图表形态及性别色常量等待实现项。

## What Changes

### 主题定时与定制

- 引入 **用户基线主题** 与 **生效主题** 分层：19:00–05:00 生效主题固定为夜空；05:00–19:00 恢复持久化基线；**无论用户基线是否已为夜空，均走同一套公式**（已选夜空时晚间切换视觉上无变化）。
- 设置页保留 **经典**、**夜空** 两个命名预设；**移除** 六个固定浅色 swatch（softBlue…softPurple）及仅含六色的 `MaterialColorPicker`。
- 新增 **颜色选盘**（HSV/色轮），用户可选任意 ARGB 作为自定义背景 seed（`preset=null`）；旧 soft preset 加载时迁移为自定义 seed。
- 女性 `BabySex.female` 经典主色由深红改为 **玫瑰红**（如 `#E91E63`）。

### UCG 与图表

- `AppVisualTokens` 增加 **`onRecordsCard`**（基于 `recordsCardColor` 的可读前景色）；UCG 内凡使用浅色 `recordsCardColor` / light glass 背景的组件 MUST 使用该 token，修复夜空下白底白字。
- 主页 `HomeEventHourlyTrendChart` 今/昨序列 **`isCurved: false`**，呈现折线而非平滑曲线。
- 若 `hide-ucg-treasure-entry` 规格已落地但资料卡与动态列表仍有 TabBar 占位空白，须将占位高度归零（与 `ucg-profile` 既有场景对齐）。

### 与 sibling change 的边界

- **新帖**发表后导航至「我的」并刷新、**编辑帖**成功后仅 pop 回详情：以 `ucg-compose-bg-upload-publish-theme` 为准；本 change 的 `ucg-compose-post` delta 仅作行为对齐引用，实现时避免重复冲突。
- **定时主题**核心调度若已在 sibling change 实现，本 change 须确保 **统一公式**（无「已选手动夜空则跳过」分支）及设置页选中态展示 **基线** 而非生效主题。

## Capabilities

### New Capabilities

- `app-theme-schedule`：本地 19:00/05:00 夜空与用户基线恢复；基线持久化不受定时覆盖；resume/周期 tick 重算
- `app-theme-customization`：经典/夜空预设 + 任意色选盘；女性玫瑰红；soft preset 迁移

### Modified Capabilities

- `ucg-visual-system`：暗色 shell 下浅色 surface 卡片 MUST 使用 `onRecordsCard` 等可读前景，不得白底配 `onShell` 白字
- `home-event-hourly-trend`：今/昨双序列 MUST 为折线（非平滑曲线）
- `ucg-profile`：宝藏关闭时资料卡与动态列表之间不得保留 TabBar 占位高度（若实现未达标则补齐）
- `ucg-compose-post`：编辑成功 pop 回详情、新帖成功导航「我的」（与 sibling change 一致，避免行为分叉）

## Impact

**flutter_ai_talk**

| 区域 | 路径 |
|------|------|
| 主题调度 | `app_theme_scope.dart`、新建 schedule helper、`app.dart` |
| 主题持久化 | `custom_background_persist.dart`、`theme_preset.dart` |
| 设置 UI | `settings_screen.dart`；可能新增 `flex_color_picker` 或等价依赖 |
| Token | `app_visual_tokens.dart`、`theme_preset.dart`（`onRecordsCard`） |
| UCG 对比度 | `ucg_visual_widgets.dart`、`ucg_compose_light_glass_panel.dart` 及 UCG 内 `onShell`+浅色底误用处 |
| 图表 | `home_event_hourly_trend_chart.dart` |
| 资料页 | `ucg_profile_shell.dart`（占位高度） |

**go_ai_talk**：无变更。

**依赖关系**：与 `ucg-compose-bg-upload-publish-theme` 协调定时主题与发表导航，避免双份 Provider 或冲突导航逻辑。

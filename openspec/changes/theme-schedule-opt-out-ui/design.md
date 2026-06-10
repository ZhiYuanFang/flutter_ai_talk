## Context

`theme-schedule-ucg-visual-polish` 已实现 `effectiveThemeProvider` 与 19:00–05:00 强制夜空，但首版 design 将「关闭定时开关」标为 Non-Goal。用户反馈晚间自定义色「无效」。当前设置页将 HSV 色盘常显，且有「清除自定义背景」ListTile。

## Goals / Non-Goals

**Goals:**

- 默认开启自动夜空；用户可在设置页标题行关闭
- 自动夜空开启时隐藏自定义色入口，避免误解；已存自定义基线保留，白天仍展示
- 自动夜空关闭时：经典 / 夜空 / 彩色三 swatch；色盘折叠，点彩色 toggle
- 移除「清除自定义背景」；点「经典」即恢复默认
- 持久化 `theme_schedule_enabled`（默认 `true`）

**Non-Goals:**

- 修改 19:00 / 05:00 边界或时区策略
- 后端同步主题偏好
- 设置页实时预览 effective vs baseline 双主题

## Decisions

### 1. 持久化字段

**选择**：`SharedPreferences` 键 `theme_schedule_enabled`，布尔，缺省/未写入视为 `true`。

**理由**：与现有 `custom_bg_color`、`theme_preset_id` 同层；老用户无键仍自动夜空。

### 2. 调度公式

**选择**：

```dart
ThemePreferences resolveDisplay(DateTime now, ThemePreferences baseline, {required bool scheduleEnabled}) {
  if (scheduleEnabled && isNightWindow(now)) {
    return const ThemePreferences(seed: kNightSkyShell, preset: ThemePreset.nightSky);
  }
  return baseline;
}
```

**理由**：最小改动；关闭后 24h 跟基线。

### 3. Provider 分层

**选择**：新增 `themeScheduleEnabledProvider`（`StateProvider<bool>`）；`effectiveThemeProvider` watch 该值；冷启动 `applyUserThemeBaseline` 一并加载。

### 4. 设置页布局

**选择**：

- 将「主题」标题改为 `Row`：`Text('主题')` + `Spacer` + `Text('自动夜空')` + `Switch`
- `_ThemePresetSection` 改为 `ConsumerStatefulWidget`（或外层 Stateful）持有 `_colorWheelExpanded`
- `scheduleEnabled == true`：仅 `Wrap([经典, 夜空])`
- `scheduleEnabled == false`：`Wrap([经典, 夜空, 彩色])` + 条件渲染 `_CustomThemeColorPicker`

**彩色 swatch**：

- 无自定义 seed：彩虹渐变或 palette 图标
- 有 seed：实色 + `isCustom` 选中描边
- `onTap`：toggle `_colorWheelExpanded`；首次展开可选中自定义模式

**点经典/夜空**：收起色盘（`expanded = false`）。

### 5. 自动夜空开 + 已有自定义基线

**选择**：不清理磁盘 seed；05:00–19:00 effective 仍用自定义 bundle；设置页不展示彩色块（用户不能改，但白天 App 仍显示该色）。

**理由**：用户已确认 OK。

### 6. 移除「清除自定义背景」

**选择**：删除 ListTile；恢复经典仅通过「经典」swatch（现有 `_clearToClassic` 逻辑保留于 swatch onTap）。

**备选**：保留隐藏入口 —— 用户明确要求删除。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 用户关自动夜空后不知晚间不再变暗 | Switch 旁可选一行 subtitle「19:00–05:00 自动切换夜空」（仅 ON 时） |
| 已有自定义色 + 开自动夜空，设置页看不出当前基线 | 可接受；用户白天能看到 App 效果；若需可在经典 swatch 旁不加额外态 |
| 折叠色盘 state 在切换 schedule 时未重置 | 关→开 schedule 时强制 `expanded=false` |

## Migration Plan

1. 部署后老用户无 `theme_schedule_enabled` 键 → 读为 `true`，行为与现网一致
2. 无数据迁移；UI 移除清除入口不影响已存 seed

## Open Questions

（无——用户已确认基线保留策略与删除清除入口。）

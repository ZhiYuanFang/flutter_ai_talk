## Context

当前主题由 `themePresetProvider` + `customBackgroundProvider` 持久化偏好直接驱动 `buildAppTheme()`，无时间调度。设置页提供「经典」「夜空」及六个固定 soft swatch；「更多颜色」弹窗仍限于 `kThemeSoftSwatchColors` 六色。`AppVisualTokens` 含 `onShell`（深色 shell 上为浅色字）与 `recordsCardColor`（暗色 shell 下为 0.94 亮度浅卡），UCG 卡片普遍用浅底 + `onShell` 导致夜空不可读。`HomeEventHourlyTrendChart` 已用 `fl_chart` 的 `LineChart` 但 `isCurved: true`。

Sibling change `ucg-compose-bg-upload-publish-theme` 已规格化定时主题与新帖导航；本设计在其基础上补齐 **统一调度公式**、**颜色选盘**、**onRecordsCard token** 与 **折线图形态**，并协调避免重复 Provider。

## Goals / Non-Goals

**Goals:**

- 用户基线与生效主题分离；19:00–05:00 一律夜空，05:00–19:00 一律基线，无「已选夜空则跳过」分支
- 设置页：经典 + 夜空 + 内嵌/弹窗 HSV 色盘任意自定义色
- 女性经典色改为玫瑰红 `#E91E63`（或设计评审后微调）
- `onRecordsCard` token + UCG 浅色 surface 可读性修复
- 今/昨小时图改为折线（`isCurved: false`）
- 宝藏关闭时资料页无 TabBar 占位（若代码未达标则补齐）

**Non-Goals:**

- 后端 API 变更
- 用户关闭定时夜空的开关（首版不做）
- 替换 `TrendGlassBarChart` 柱状趋势页
- 重做 UCG 发布媒体管线（属 sibling change）

## Decisions

### 1. 主题分层：`userTheme` vs `effectiveTheme`

**选择**：新增 `effectiveThemeProvider`（或等价 computed provider），`MaterialApp.theme` 只读 effective；设置页读写 user 偏好 provider。

```dart
bool isNightWindow(DateTime local) {
  final m = local.hour * 60 + local.minute;
  return m >= 19 * 60 || m < 5 * 60;
}

EffectiveTheme resolve(UserTheme user) =>
  isNightWindow(DateTime.now())
    ? EffectiveTheme.nightSky()
    : EffectiveTheme.fromUser(user);
```

**理由**：统一公式；用户已存夜空时晚间 effective 仍为 nightSky，视觉无变化。

**备选**：19:00 写盘 preset=nightSky —— 拒绝，会破坏 05:00 恢复。

### 2. 调度触发

**选择**：`Timer.periodic(1.minute)` + `WidgetsBindingObserver` 在 `resumed` 时 `invalidate` effective theme。

**理由**：与 sibling spec 一致；跨边界后台恢复可靠。

### 3. 设置页选中态

**选择**：Swatch 选中反映 **user 基线**（`themePresetProvider` / `customBackgroundProvider`），不反映 effective 临时夜空。

**理由**：用户晚上 8 点看到夜空 UI，但设置里仍应显示「自定义粉蓝」为选中。

### 4. 颜色选盘 UI

**选择**：保留「经典」「夜空」两个 `_PresetSwatch`；移除六个 soft swatch；在设置页增加 **内嵌色盘**（优先 `flex_color_picker` 的 `ColorPicker` 紧凑模式，或 `flutter_colorpicker`）。

**理由**：用户明确要求在经典/夜空基础上任意选色；内嵌比二次弹窗更直观。

**备选**：仅弹窗 —— 可接受 fallback，但 proposal 倾向内嵌。

### 5. Soft preset 迁移

**选择**：`loadThemePreferences()` 若 preset 为 `softBlue`…`softPurple`，转为 `preset: null, seed: _swatchColorForPreset(preset)` 并回写磁盘。

**理由**：enum 保留兼容解析，UI 不再展示。

### 6. `onRecordsCard` token

**选择**：在 `VisualBundle.toTokens()` 中 `onRecordsCard = _readableOn(recordsCardColor)`；扩展 `AppVisualTokens`；UCG 中 `UcgSurfaceCard`、`ucgComposeLightTextColor*`、compose light glass 内文改用 `onRecordsCard` 或对 light fill 调用 `_readableOn(fillTop)`。

**理由**：比逐文件 hardcode 更稳；主页历史浅卡若已用正确色则同步受益。

**备选**：暗色 shell 下 UCG 改用 `surfaceColor` 深卡 —— 拒绝，与主页历史亮卡设计语言不一致。

### 7. 折线图

**选择**：`HomeEventHourlyTrendChart` 两条 `LineChartBarData` 设 `isCurved: false`；保留现有 dot 隐藏与颜色逻辑。

### 8. 与 sibling change 协调

**选择**：若 `ucg-compose-bg-upload-publish-theme` 已合并 effective theme provider，本 change 在其上追加 unified formula 与 settings UI；若未合并，本 change 一次性实现 provider + UI。发帖导航以 sibling tasks 为准，本 change tasks 仅作交叉检查项。

## Risks / Trade-offs

- **[Risk] 色盘依赖体积** → 选用轻量 picker 或限制为 HSV 滑条 + 色相环
- **[Risk] 与 sibling change 双份 theme provider** → 实现前 grep 仓库，复用已有 helper
- **[Risk] UCG 漏改 onShell** → tasks 含 UCG 目录 grep 验收清单
- **[Risk] 老用户 soft preset 迁移闪屏** → 迁移在 cold start 一次写盘

## Migration Plan

1. 部署 token + theme provider（向后兼容，无数据破坏）
2. cold start 执行 soft preset → custom seed 迁移
3. 设置页 UI 替换；用户下次打开设置可见色盘
4. UCG 对比度与图表改动纯客户端，无回滚数据需求

## Open Questions

- 玫瑰红最终 hex：默认 `#E91E63`，实现时可微调
- 色盘 **内嵌** vs **弹窗**：design 倾向内嵌，实现可按设置页空间微调

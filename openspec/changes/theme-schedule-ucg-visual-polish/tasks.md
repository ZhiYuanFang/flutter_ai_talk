## 1. 主题调度与基线分层（app-theme-schedule）

- [x] 1.1 检查 `ucg-compose-bg-upload-publish-theme` 是否已有 effective theme 实现；若无则新建 `isNightWindow` helper 与 `effectiveThemeProvider`
- [x] 1.2 `PangbaoApp.build` 改为用 effective theme 调用 `buildAppTheme`；持久化仍只写 user 基线 provider
- [x] 1.3 实现统一公式：19:00–05:00 一律 `nightSkyBundle`，无「基线已是夜空则跳过」分支
- [x] 1.4 添加 `Timer.periodic(1.min)` + `WidgetsBindingObserver.resumed` 触发 effective theme 重算
- [x] 1.5 设置页 swatch 选中态绑定 user 基线 provider，非 effective 主题

## 2. 主题定制 UI（app-theme-customization）

- [x] 2.1 `sexPrimary(BabySex.female)` 改为玫瑰红 `#E91E63`
- [x] 2.2 设置页移除 softBlue…softPurple 六个 swatch 及仅六色的 `MaterialColorPicker` 主入口
- [x] 2.3 添加颜色选盘依赖（如 `flex_color_picker`）并在设置页内嵌 HSV/色轮控件
- [x] 2.4 选色确认：写 `preset=null` + seed，更新 provider 并 `persistThemePreferences`
- [x] 2.5 `loadThemePreferences` 迁移 soft preset → `preset=null` + 对应 seed 并回写

## 3. onRecordsCard token（ucg-visual-system）

- [x] 3.1 `AppVisualTokens` 增加 `onRecordsCard`；`VisualBundle.toTokens()` 用 `_readableOn(recordsCardColor)` 赋值
- [x] 3.2 `UcgSurfaceCard` / `UcgSectionLabel` 等浅底组件改用 `onRecordsCard`
- [x] 3.3 `ucgComposeLightGlassPanel` 与 `ucgComposeLight*Color` 对 light fill 使用可读前景（`onRecordsCard` 或 `_readableOn(fillTop)`）
- [x] 3.4 扫描 `app/lib/ucg/**`：`recordsCardColor`/light glass 背景处不得 paired `onShell` 白字；手工夜空路径验收

## 4. 今/昨折线图（home-event-hourly-trend）

- [x] 4.1 `HomeEventHourlyTrendChart` 两条 `LineChartBarData` 设 `isCurved: false`
- [x] 4.2 手工验证：今日 chip → 趋势 sheet，确认折线非平滑曲线且零数据仍显示

## 5. 资料页占位（ucg-profile）

- [x] 5.1 检查 `kUcgTreasureEnabled=false` 时 `UcgProfileShell` 是否仍保留 TabBar/TabBarView 占位
- [x] 5.2 若存在空白：`NestedScrollView.body` 直接挂动态列表，`floatHeaderSlivers=false`，去除 TabBar 高度占位
- [x] 5.3 验证资料卡操作按钮不被动态列表遮挡

## 6. 交叉检查（sibling change）

- [x] 6.1 若 `ucg-compose-bg-upload-publish-theme` 未实现：按该 change 规格补齐新帖→「我的」、编辑→pop 详情；若已实现则仅回归
- [x] 6.2 `flutter analyze` / 本地 `flutter run`：经典、自定义色、夜空、21:00 定时、UCG 广场/发布/资料页可读性

## 1. 辩论类别色原子

- [x] 1.1 在 `AppVisualTokens` / `theme_preset.toTokens` 增加辩论左右侧渐变与字色、VS chip 填色/描边/前景字段（初值对齐现有马卡龙 hex）
- [x] 1.2 在 `AppColor` 暴露 `debate*` 入口；`UcgDebateVisualTokens` 去掉色常量或改为仅转发

## 2. 广场 / 辩论卡挂 panelGlass

- [x] 2.1 `UcgFeedFakeGlassPanel` 改用 `panelGlassGradient` + `divider`；helper 改挂 `textOnPanelGlass*`
- [x] 2.2 确认辩论 Feed 卡、arguments、`ucg_debate_share` 随 panel 取色；分享 backdrop 不再用 `contentCard`

## 3. VS 条与硬编码清扫

- [x] 3.1 `ucg_debate_vs_bar.dart` 全部类别/描边/钮色改经 `AppColor.debate*`（无内联 `Color(0x…)` / 零散 `Colors.white` 作角色色）
- [x] 3.2 UCG 内卡 chrome / 壳字路径：`UcgTheme` 转发 `AppColor`；扫 `onShell`/`onRecordsCard` 直读与假玻璃相关硬编码
- [x] 3.3 媒体沉浸遮罩收口到 `AppColor` 单一入口（或已有 `barrier`）；删除红用 `colorScheme.error`

## 4. 文档与验收

- [x] 4.1 `project.md` / `AppColor` 注释补充：UCG 广场与辩论挂 panelGlass；辩论类别色走原子
- [ ] 4.2 手动矩阵：夜空下广场/辩论卡暗浮层可读、左右侧可辨；经典浅壳可读；预测 chrome 无回归

## 1. 原子与派生

- [x] 1.1 扩展 `AppVisualTokens`：`panelGlassTop` / `panelGlassBottom` / `onPanelGlass`（copyWith/lerp）
- [x] 1.2 `VisualBundle.toTokens()` 按 design D2 派生；暗壳 top 禁止近白 contentCard 起笔
- [x] 1.3 `AppColor`：`panelGlassTop` / `panelGlassBottom` / `textOnPanelGlass` / `textOnPanelGlassMuted` / `panelGlassGradient({accent})` 及场景注释
- [x] 1.4 `project.md` 主题色约定补充 panelGlass ≠ contentCard / modal

## 2. 预测页迁入

- [x] 2.1 tip 玻璃条改 `panelGlassGradient` + `textOnPanelGlass*`
- [x] 2.2 `_CareAlertShell` 改 panelGlass；标题/正文配对字色
- [x] 2.3 预测事件卡外壳改 `panelGlassGradient(accent: eventColor)`；去掉手拼 contentCard 白叠

## 3. 验收

- [x] 3.1 `dart analyze` 触达文件无 error
- [ ] 3.2 手工：夜空 tip/留意/事件卡不发白且字可读；经典浅色可接受；事件卡仍有事件色倾向
- [x] 3.3 `openspec validate theme-panel-glass-atoms --strict` 通过

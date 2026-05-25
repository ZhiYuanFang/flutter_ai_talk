## 1. 布局常量与绘制组件

- [x] 1.1 抽取或文档化圆点列宽、圆点中心 x、行高常量（与 `HomeHistoryTimelineTile` 共用）
- [x] 1.2 新增 `HomeHistoryDayTimelineLinksPainter`（或等价）：输入相邻行事件色列表，绘制竖向渐变线段

## 2. 日卡片接入

- [x] 2.1 在 `_buildDayRecordsCard` 用 `Stack` 叠连图层 + 现有 `Column` tiles
- [x] 2.2 按 `recordsOldestFirst` 解析每行 `resolveEventColor` 并传入 painter
- [x] 2.3 `RepaintBoundary` / `shouldRepaint` 仅在 records 或 catalog 变化时重绘

## 3. 边界与交互

- [x] 3.1 单日 1 条：不绘制；跨日：各卡片独立
- [x] 3.2 确认整行点击、停止按钮、飞行动画锚点不受连线影响

## 4. 验证

- [x] 4.1 `flutter analyze` 相关文件
- [x] 4.2 手工：同日 2+ 条渐变连线、异色事件、单日 1 条、跨两日、跟底滚动

## 1. 展示模型

- [x] 1.1 在 `history_line_format.dart` 新增 `HistoryHomeRowDisplay` 与 `historyHomeRowDisplay(record, now)`，对齐现有 `eventNumber` 分支
- [x] 1.2 单元逻辑自洽：计数 / 计时中 / 已结束 / 备注 各态尾注与时间字段正确

## 2. 时间轴行组件

- [x] 2.1 新增 `home_history_timeline_tile.dart`：`HomeHistoryTimelineTile`（左时间、中事件、右尾注、底部项高亮圆点）
- [x] 2.2 支持 `fromBottom` 字号梯度（约 13→11）与颜色弱化，移除 per-item `Opacity`

## 3. 列表集成

- [x] 3.1 `home_screen.dart`：`itemBuilder` 改用 `HomeHistoryTimelineTile` + `historyHomeRowDisplay`
- [x] 3.2 历史 `ListView` 外包顶部 `ShaderMask`（或 Stack 渐变）实现向上淡出
- [x] 3.3 收紧 `padding`/`itemExtent`，验证 reverse 列表最新条仍在底部且可点击进详情

## 4. 验证

- [x] 4.1 真机/模拟器：多条历史下顶部旧记录淡出、底部最新行最清晰，行高约一行半字
- [x] 4.2 计时中、计数、带备注记录三类展示正确；与今日概览同时存在时不布局溢出

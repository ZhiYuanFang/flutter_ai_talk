## 1. 实现

- [x] 1.1 `_yAxisStep`：`span/4` 改为 `span/2`（固定约 3 刻度）；必要时将 `maxY` 对齐到 `minY+2*step`
- [x] 1.2 确认左侧 titles / 水平网格使用同一 step

## 2. 验收

- [x] 2.1 手工：正常折线 Y 轴为 3 个时刻标签
- [x] 2.2 未改 `app/android/**`；不强制 release APK

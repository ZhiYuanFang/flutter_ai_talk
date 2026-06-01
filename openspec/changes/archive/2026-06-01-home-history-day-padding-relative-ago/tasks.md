## 1. 相对时间文案

- [x] 1.1 更新 `formatHistoryRelativeAgo`：`<60s` → `刚刚`；`≥60s` 且 `<1h` → `{m}分前`；`≥1h` → `{h}时{m}分前`

## 2. 日卡片内边距

- [x] 2.1 `_buildDayRecordsCard`：在 `ClipRRect` 内为 `Stack`（连线 + `Column`）增加统一 `Padding`（建议 8）
- [x] 2.2 确认连线与圆点在内边距后仍对齐

## 3. 验证

- [x] 3.1 `flutter analyze` 相关文件
- [x] 3.2 手工：卡片内留白、59s/1m/59m/1h 文案、多事件 badge、连线

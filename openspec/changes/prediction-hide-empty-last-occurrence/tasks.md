## 1. 展示门闩

- [x] 1.1 `smart_prediction_screen.dart`：仅 `row.lastAt != null` 时生成/展示「上一次」行；null 时不渲染（无「暂无」）
- [x] 1.2 确认 `showAddLastOccurrence`（「补充上一次」）在 `lastAt == null` 时仍可出现；计时中路径不变

## 2. 验收

- [ ] 2.1 无 lastAt 热态卡：无「上一次…暂无」行，有「补充上一次」（开推演且门闩满足时）
- [ ] 2.2 有 lastAt：仍显示「上一次…」时刻；可点编辑行为与改前一致
- [ ] 2.3 切号/空 tip 瞬间：不闪「暂无」；历史到达后行自然出现

## 3. 收尾

- [x] 3.1 不改 tip 存储/wipe；无 `app/android/**` 改动

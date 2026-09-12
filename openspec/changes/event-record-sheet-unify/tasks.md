## 1. 时间行原子

- [x] 1.1 新增居中分段时间行组件（日小/时大、`·` / `~` /「进行中」可点；复用日期/时分 picker）
- [x] 1.2 核对日文案与 `formatHistoryDaySectionLabel` 一致

## 2. 统一主 Sheet

- [x] 2.1 实现 `showEventRecordSheet` + `EventRecordIntent`（标题仅事件名、按 type 显隐字段）
- [x] 2.2 supplement / add·number：初值今日·当下；time 结束可选；无清除结束
- [x] 2.3 edit：迁入统一壳（媒体/删/广场仅 edit）；去掉「清除结束时间」；保留开始/结束对齐规则

## 3. 调用链

- [x] 3.1 `handleEventGridTap` / `_onEventButtonTap` 支持 intent；add·非量仍 now；number→统一 Sheet
- [x] 3.2 预测无 lastAt：点卡与「补充上一次」→ supplement；add·非量保留「确认添加」
- [x] 3.3 喂养格 / 历史编辑入口改调统一 Sheet；薄封装或删除旧 number/edit 主壳

## 4. 验收

- [ ] 4.1 手工：补充 one/time/number；无 lastAt 点卡=CTA；有 lastAt 非量仍确认后 now
- [ ] 4.2 手工：新增 number 跨日；编辑标题与时间行；无清除结束
- [x] 4.3 `dart analyze` 相关文件；不新建 `**/test/**`；无 `app/android/**` 必改

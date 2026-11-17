## 1. 种子与池模型

- [x] 1.1 在统一历史 notifier（优先扩展 `homeHistory`）实现近 7 日一次 `filter` 种子（single-flight、失败熔断）；触顶 500 截断且不连环 `v2/list`
- [x] 1.2 调整磁盘快照字段：以池 items + `hasMoreOlder`（或等价）替代「list 页深」作为 loadMore 主依据；切号擦除覆盖新字段
- [x] 1.3 主壳/`deviceNo` 就绪后触发种子；确认 Splash 不 await 该 HTTP

## 2. 时间游标 loadMore

- [x] 2.1 实现 loadMore：`endTime = 最旧 startTime − 1` + 小 limit（filter 或 v2）；id 去重合并；空页结束 `hasMoreOlder`
- [x] 2.2 喂养页下拉绑定新 loadMore；去掉以 `list?page=N` 为主路径的逻辑（可留兼容但不得作为种子后主路径）
- [x] 2.3 下拉刷新：重跑一次 7 日种子；默认保留窗起点之前的更旧行（若过复杂则整表重种子并在 PR 说明）

## 3. 拆除双拉与预测接线

- [x] 3.1 删除或挖空 `predictionRangeHistory` 远端 ensure；主壳不再并行 range + list page1
- [x] 3.2 `predictionRealHistoryProvider` / widget sync / 亲和输入改为只读统一池（可本地 7 日切片，无第二套 HTTP）
- [x] 3.3 清理 `mergeRealHistoryById(home∪range)` 等仅服务双源的胶水；WS upsert 仍写统一池

## 4. 校验

- [x] 4.1 手工：冷启动一次 filter 有近窗；预测与喂养同源；loadMore 出现更旧且不重拉 7 日
- [x] 4.2 手工：WS 增删两边可见；切号后池空
- [x] 4.3 若本变更改动 `app/android/**` 或原生 SDK：跑 `flutter build apk --release` 并按需更新 `proguard-rules.pro`（否则标 N/A）

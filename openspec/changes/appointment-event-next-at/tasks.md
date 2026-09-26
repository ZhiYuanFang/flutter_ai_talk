## 1. 模型与目录

- [x] 1.1 `EventDefinition` / options 解析增加 `isAppointment`（缺省 false）；`catalogSnapshotsEqual` 与落盘重建包含该字段
- [x] 1.2 预约相关路径统一解析为 catalog 根 eventId

## 2. 预约下次 API

- [x] 2.1 实现 `GET/PUT /device/app/api/appointment/next` repository（Bearer；deviceNo；秒级 nextAt）
- [x] 2.2 编辑 history：打开 GET 回填并展示下次；点击打开专用 sheet；提供清空（PUT 0 + pending omit）
- [x] 2.3 仅改 history 字段时不误清 nextAt（原样保留或按需写回已读值）

## 3. 专用下一次预约 sheet

- [x] 3.1 实现上下布局 sheet：上文案「{logo}下一次{事件名}预约时间」；下年月日时分滚轮；确认 PUT 正 nextAt 并同步 pending；**无清空**
- [x] 3.2 预测卡「补充下次」打开该 sheet
- [x] 3.3 正常新增成功后：空或过期才弹该 sheet；未来 nextAt 不弹；**不改**原新增页
- [x] 3.4 「补充上一次」成功后：同样仅空/过期弹该 sheet

## 4. 预测与 pending

- [x] 4.1 预约根跳过间隔预测与 recall 种子；有 nextAt（含过期）用其作为预测结果；UI 标过期
- [x] 4.2 无约定：不进 pending；卡仍可展示「补充下次」
- [x] 4.3 清空/无约定：pending omit 该根 eventId；有约定：纳入 pending 整表同步

## 5. 验收

- [x] 5.1 对照 `appointment-event-client` 与三条 MODIFIED specs 情景走查（含仅编辑页可清、过期仍推）
- [ ] 5.2 与后端联调：options 标志、读写 nextAt、清空后不误推、过期仍上报

## 0. 对端依赖

- [x] 0.1 确认 Go `appointment-next-remark` 已合入（GET/PUT 含 `remark`，max 512，必传字符串，`nextAt=0` 清备注）；本仓备注任务不得用假字段占位

## 1. 准确率图区手势与竖列表过滤

- [x] 1.1 `_PredictAccuracyChartPane`：小结态整区单击清 `_summaryDay`（等同返回）；柱图空白仍吸收加事件
- [x] 1.2 图区（柱图/小结）显式 `onLongPress` → 与整卡相同的 list↔瀑布 toggle 回调
- [x] 1.3 竖列表构建前过滤 `catalogRootIsAppointment` 根；瀑布/横屏 compact 不过滤

## 2. 预约卡展示与 history 备注

- [x] 2.1 瀑布/compact 预约卡文案：预测/预计 → 预约语义
- [x] 2.2 预约卡推演开：logo 固定标题行左侧，禁用居中大图
- [x] 2.3 上次发生行：最新 history 时间 + 非空 ` · {remark}`

## 3. 下次预约备注（跟 Go）

- [x] 3.1 `AppointmentNextRepository` / cache：GET/PUT 读写 `remark`
- [x] 3.2 `appointment_next_sheet`：备注输入；打开默认回填 GET 的上次预约备注；确认一并 PUT
- [x] 3.3 热态卡预约时刻后展示非空下次 ` · {remark}`

## 4. 一次性 / time 预测卡新增

- [x] 4.1 预测卡 `time|one` 普通 `add`：去掉「确认添加」即时 now，改为打开统一记录 sheet（与编辑态同族）

## 5. 主题 onPrimary

- [x] 5.1 `buildAppThemeFromBundle`：覆盖 `primary` 时同步 `onPrimary`
- [x] 5.2 `event_record_sheet` / 编辑保存钮统一 `AppColor.onPrimary`，去掉写死白/黑

## 6. 联调

- [ ] 6.1 与 Go 联调：备注读写、nextAt=0 清备注、改约默认回填；竖列表无预约卡；准确率手势；one 走 sheet

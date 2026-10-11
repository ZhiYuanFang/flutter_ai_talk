## 1. 推算与文案

- [x] 1.1 基于进行中记录 + 根 duration 有把握计算 `expectEndAt`（复用 expect-amount-duration 时长秒）
- [x] 1.2 实现「预计约 HH:mm 结束」与超时「· 已超时」格式化（列表/网格共用）

## 2. 预测页 UI

- [x] 2.1 网格/compact 进行中卡展示 ETA；无 ETA 不占位
- [x] 2.2 列表态进行中卡同等展示 ETA（不得仅网格可见）

## 3. 同步

- [x] 3.1 新增 active-eta repository：PUT 全量 items（root/leaf/historyId/title/startAt/expectEndAt）
- [x] 3.2 sync provider：single-flight、指纹含 ETA、熔断；开始/停止计时与合格本机变更后触发；空列表清空
- [x] 3.3 与 Go 同名 change 路径/字段联调核对

## 4. 验收

- [ ] 4.1 手工：睡眠进行中 + duration 有样本 → 列表与网格均见预计结束
- [ ] 4.2 手工：拨快时间或短时长样本使超时 → 见「已超时」且时刻仍为原预计
- [ ] 4.3 手工：停止计时后 pending/active-eta 同步为空或不再含该项

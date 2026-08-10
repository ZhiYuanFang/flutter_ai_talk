## 1. 引擎与聚合

- [x] 1.1 将评估改为返回全量 `List<CareAlertReason>`（移除全局 Top1 类型丢弃）
- [x] 1.2 新增按 `eventId` 聚合的 `CareAlertEventItem`（多规则类型标签按优先级连接为 `summaryLine`）
- [x] 1.3 跨事件排序：最高类型优先级 → 同级最大 score；provider 改为输出 `List<CareAlertEventItem>`

## 2. 跑马灯 UI

- [x] 2.1 替换单 Banner 为「值得留意」区块：viewport **严格裁切只见一行**（不露下一条）
- [x] 2.2 ≥2 条自动上下循环轮播；1 条静止；支持手动滚动；拖动后短暂暂停再恢复
- [x] 2.3 摘要单行 `maxLines: 1` + 尾部省略；空列表整块隐藏

## 3. 详情与路由

- [x] 3.1 `/prediction/alert` 的 extra 改为 `CareAlertEventItem`；详情全量展示该事件全部 reasons
- [x] 3.2 点击跑马灯当前条 push 对应事件详情

## 4. 验收

- [x] 4.1 验证：A 间隔拉长 + B 进行中过久时两条都在跑马灯中且可滑到；视口不露半行
- [x] 4.2 验证：同事件多规则摘要一句话；详情列出全部原因；无候选时区块不占位
- [x] 4.3 与 `prediction-layout-list-grid` 并存：网格布局下跑马灯仍全宽在卡片区上方

## 1. 停止与匹配

- [x] 1.1 抽取或对齐喂养停止逻辑（写 `endTime`、无确认、失败 toast），供预测页网格卡复用
- [x] 1.2 由 `homeHistoryProvider` 解析各预测行是否有进行中计时及对应 `HistoryRecord`

## 2. 网格卡 UI

- [x] 2.1 compact + active：名左侧小 logo、中间 elapsed、底「停止」、保留推演开关；隐藏 nextAt 倒计时与大图主区
- [x] 2.2 停止区不触发整卡加事件；停止中禁用按钮；`predictionClockProvider` 驱动 elapsed
- [x] 2.3 确认 `!compact` 列表卡无行为/布局变更

## 3. 验收

- [x] 3.1 手工：有进行中计时时网格卡为计时 chrome；停止后恢复倒计时；推演开关仍可操作；列表态外观不变

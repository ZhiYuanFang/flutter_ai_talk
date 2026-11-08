## 1. History filter 接线

- [x] 1.1 `FeedRepository` / `RemoteFeedRepository.tryLoadHistoryFilter` 增加 `ignoreTimeRange` 并写入 query
- [x] 1.2 预约上次发生：按根+子 `eventIds`、`limit=1`、`ignoreTimeRange=true` 拉取；single-flight / 短缓存；失败可回退窗内时间但不得假备注

## 2. 预约卡展示

- [x] 2.1 瀑布/compact 预约卡「上一次」优先用不限窗 filter 结果（时间 · history remark）

## 3. 预约 sheet 键盘与滚轮

- [x] 3.1 `showAppointmentNextSheet`：`respectKeyboardInset: true`；备注 `keyboardLiftTarget` + FocusNode
- [x] 3.2 备注获焦或键盘可见时收起四列滚轮；失焦且键盘收起后恢复

## 4. 联调

- [ ] 4.1 真机：久未记录预约卡上次+备注；备注获焦滚轮收起且输入不被盖

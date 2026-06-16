# Tasks: home-history-edit-date-picker

## 1. 日期滚轮组件

- [x] 1.1 新增 `showHomeHistoryDatePickerSheet`（玻璃态 Bottom Sheet + `CupertinoDatePicker` date 模式，`minimumDate` / `maximumDate` 入参）
- [x] 1.2 新增 `HomeHistoryDateField`（文字展示 `formatHistoryDaySectionLabel`，点击打开日期 Sheet）
- [x] 1.3 新增 `HomeHistoryDateTimeRow`（label + 并排 `HomeHistoryDateField` 与 `HomeHistoryTimeField`）

## 2. 编辑 Sheet 接入

- [x] 2.1 `home_history_edit_sheet`：从 `settingsBabyProvider` 解析宝宝生日与今天，计算 picker 范围
- [x] 2.2 将 `n==0` 的开始/结束、`n>=1` 的结束时间字段替换为 `HomeHistoryDateTimeRow`；时间 `anchorDate` 使用当前编辑值的日历日
- [x] 2.3 确认 `_isFormDirty`、`_save`、pending 只读与「结束不能早于开始」在改日期后仍正确
- [x] 2.4 `eventNumber == 0`：改开始日仅同步结束日历日（保留结束时/分）；改开始时分且晚于结束时同步结束时刻

## 3. 验证

- [ ] 3.1 手工验证：`n=0` 改开始/结束日期、跨天保存；`n=1` / `n>1` 改结束日期；日期文案显示今天/昨天；picker 范围宝宝生日～今天；pending 不可点
- [x] 3.2 确认 `home_number_event_sheet` 与主页新建流程行为未变

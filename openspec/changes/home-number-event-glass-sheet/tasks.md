## 1. 弹层外壳

- [x] 1.1 `showHomeNumberEventSheet` 改为透明 `showModalBottomSheet` + 半透明 barrier
- [x] 1.2 内容包裹 `HistoryEditGlassPanel`（`eventAccent`、`onClose`）

## 2. 玻璃表单布局

- [x] 2.1 头部：`EventLogo` + 事件名（玻璃浅色字）
- [x] 2.2 日期/时间：玻璃质感可点击条，保留 `showDatePicker` / `showTimePicker`
- [x] 2.3 备注：`historyEditGlassInputDecoration`；滚轮 Cupertino 浅色主题

## 3. 主操作与回归

- [x] 3.1 底部「确认记录」accent 实心圆角按钮；× 关闭不提交
- [x] 3.2 确认 `EventNumberMemoryStore`、`initialUsage`、`HomeNumberEventResult` 行为不变
- [x] 3.3 手工：奶量新增全流程、关闭不保存、记忆定位、竖屏小屏无溢出

## 4. 弹层与日期约束

- [x] 4.1 Sheet 最大高度改为屏高 4/5
- [x] 4.2 日期固定为当天不可选，仅时间可改；提交时 `startTime` 日期为今日

## 5. 时刻展示与滚轮统一

- [x] 5.1 当天日期纯文本展示于上方（无边框）
- [x] 5.2 时间改为内联时/分 Cupertino 滚轮，与用量滚轮样式一致

## 6. 时间与编辑 Sheet 对齐

- [x] 6.1 默认展示当前时分；点击 `HomeHistoryTimeField` 弹出滚轮 Sheet（同历史编辑）
- [x] 6.2 移除内联时间滚轮组件 `home_event_time_picker.dart`

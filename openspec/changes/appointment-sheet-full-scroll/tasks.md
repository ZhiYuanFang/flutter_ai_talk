## 1. 外壳与布局

- [x] 1.1 `showAppointmentNextSheet`：`scrollable: true`（保留 `respectKeyboardInset`）
- [x] 1.2 body：展示滚轮时用固定高度；去掉对非滚动有界 `Expanded` 的依赖
- [x] 1.3 保留备注获焦/键盘可见收起滚轮 + `keyboardLift`

## 2. 验收

- [x] 2.1 横屏开预约 sheet + 点备注/键盘：可滚到确认，无纵向 overflow
- [x] 2.2 竖屏：可改时间、确认；滚轮收起/恢复仍正常

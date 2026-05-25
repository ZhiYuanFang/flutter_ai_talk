## 1. HomeHistoryScroll 重锚 API

- [x] 1.1 在 `HomeHistoryScrollState` 新增 `reanchorAfterViewportChange({bool animate = true})`：跟底或距底 ≤ `followBottomThreshold` 时 `scrollToBottom(force: true, animate: animate)`，否则 no-op
- [x] 1.2 暴露 `followLatest` / 近底判定供调用方（或重锚逻辑完全内聚于 scroll state，无需 HomeScreen 读状态）

## 2. HomeScreen 切换钩子

- [x] 2.1 实现 `_scheduleHistoryReanchorAfterInputModeChange()`：post-frame 调用 `_historyScrollKey.currentState?.reanchorAfterViewportChange`，动画时长与 `AnimatedContainer` 220ms 一致；`disableAnimations` 时 `animate: false`
- [x] 2.2 在 `_selectInputChannel` channel 实际变更后调用调度
- [x] 2.3 在 `_restoreSavedInputChannel` 变更 channel 后同样调用（含 async 切 voice 路径）

## 3. 验证

- [x] 3.1 手工：文字/按钮 → 语音，跟底时最新记录自动可见
- [x] 3.2 手工：上滑非跟底时切换模式，滚动位置不被强制改变
- [x] 3.3 手工：voice ↔ text ↔ buttons 往返切换无异常

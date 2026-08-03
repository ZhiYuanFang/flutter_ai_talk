## 1. 手势与锁滑

- [x] 1.1 顶标+正文同一拖动单元；关闭/对话不参与 pan；点/拖用 slop 分流
- [x] 1.2 tip 命中盒 `pointerDown` 即 `onDraggingChanged(true)`，up/cancel 解锁；验证横滑不切 PageView
- [x] 1.3 输入模式球热区同样 `pointerDown` 锁 PageView（不必等拖动 slop）；点按切换模式保留

## 2. 点标折叠

- [x] 2.1 增加 `collapsed` 态：点顶标动画收到图标下，只留浮空圆；点圆展开
- [x] 2.2 与 `docked` 区分；新 tip generation 仍强制居中 expanded；关闭仍 dismiss

## 3. 验收

- [ ] 3.1 手工：拖顶标流畅且不带页；点标折叠/点圆展开；过半仍可贴边
- [ ] 3.2 手工：按住模式球/tip 圆横滑不切页；球外可滑页；点 tip 外历史可点；未改 Android 则无需 release APK

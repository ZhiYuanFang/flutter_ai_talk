## 1. Dock 基础设施

- [x] 1.1 新增 occupancy id（如 `prediction-home-widget`）与位置 prefs store（独立 keys）
- [x] 1.2 实现 `PredictionHomeWidgetEdgeDock`：EdgeDock 圆标、钉态 Semantics/短 caption、点按进 `/widgets/showcase`、锁滑回调

## 2. 挂载与拆除 FAB

- [x] 2.1 在 `UcgHomeShell` 于预测竖屏 + 已绑定等条件挂载小组件球（对齐语音球生命周期）
- [x] 2.2 从 `smart_prediction_screen` 移除底栏 pill FAB 与超额 `cardsBottomPad`；清理无用 FAB 组件；不新建 `**/test/**`

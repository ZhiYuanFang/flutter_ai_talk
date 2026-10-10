## 1. Lifecycle API

- [x] 1.1 调整 `syncLandscapeVoiceLifecycle`：竖屏 `surfaceVisible` 表示主壳路由当前且非 UCG 未合格；横屏仍用预测页可见；更新注释
- [x] 1.2 抽出可复用的竖屏 lifecycle binder（及字幕 toast 若预测页私有类无法被壳引用）

## 2. 主壳挂载

- [x] 2.1 `UcgHomeShell` 用 Stack 包 PageView；竖屏且 flag 开时挂 binder + `PredictionVoiceEdgeDock` + 字幕；`homePagerScrollBlocked` 仍接球占用
- [x] 2.2 UCG 未合格时不挂球层（或 surfaceVisible=false）；`ModalRoute.isCurrent` 变化时重 sync

## 3. 预测页去重

- [x] 3.1 从 `SmartPredictionScreen` 移除竖屏 EdgeDock / 字幕 / 竖屏 binder；保留横屏 chip 与横屏 binder

## 4. 验收

- [ ] 4.1 真机：主壳喂养/预测/UCG（已合格）竖屏均见同一球；滑页会话不无故拆掉
- [ ] 4.2 真机：UCG 未合格无球；推入设置后无球/会话 deactivate；预测页无双球；横屏 chip 仍仅预测页

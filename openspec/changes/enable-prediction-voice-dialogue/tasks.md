## 1. 编译期开关

- [x] 1.1 将 `kPredictionLandscapeVoiceEnabled` 与 `kPredictionPortraitVoiceEnabled` 默认改为 `true`，并更新注释（默认开启；翻 `false` 可紧急关闭）

## 2. 生命周期 activate

- [x] 2.1 修改 `syncLandscapeVoiceLifecycle`：`want` 在「预测可见 ∩ 非 Web Android/iOS ∩ ((横屏∩横屏 flag) ∨ (竖屏∩竖屏 flag))」时为 true
- [x] 2.2 核对 `smart_prediction_screen` 竖/横 binder 传参与 watch 条件；清理「竖屏改 true 常量」类过时注释，确保竖屏挂 binder 时 lifecycle 可真正 activate

## 3. 验收

- [x] 3.1 真机或模拟器：预测页横屏可见时出现左下 chip，可走唤醒/会话路径（权限未授先 rationale）
- [x] 3.2 真机或模拟器：预测页竖屏可见时出现贴边球，点按业务后会话可 activate（不得仅有球无会话）
- [x] 3.3 将任一方向 flag 临时翻 `false` 时，该方向无入口且不 activate；另一方向不受影响

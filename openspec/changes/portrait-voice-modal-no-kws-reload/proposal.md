## Why

竖屏预测语音用主壳 `ModalRoute.isCurrent` 判定「表面可见」：喂养事件选择 / 记录等 `showModalBottomSheet`、玻璃 Dialog 一打开就会 `deactivate`（`wake.stop` 释放 KeywordSpotter + chat `endSession(teardown)`），关闭后又 `activate` 并在 UI isolate 同步 `new KeywordSpotter`（`InitEncoder`），造成「先卡一下，才关」。根因是 Overlay Modal 被当成离开预测语音表面，而非真正的 Page 级导航。

## What Changes

- 竖屏预测语音生命周期：**不得**因同 Navigator 上的 Overlay Modal（bottom sheet / dialog 等 `PopupRoute`）翻转 `isCurrent` 而 teardown / 全量重载 KWS。
- 仍须在真正离开主壳表面时停会话（例如压上其它 `PageRoute`、离开可激活的竖屏表面、flag 关闭等既有条件）。
- 关喂养 sheet / 点 ✕ / 点外部关闭时：**不得**再出现成对的 `endSession reason=teardown` → 主线程 `InitEncoder` 冷启动卡顿（正常路径）。
- 可选加固：短时 Overlay 遮挡时优先 `pause` 麦流而非 `stop`+重建 spotter（若设计选定；非必须与门闩拆分同时做完）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-portrait-voice-dock`：补充竖屏语音生命周期与 Overlay Modal / PageRoute 的边界——Overlay 不得触发 deactivate+KWS 全量重载；Page 级离开仍须停会话。

## Impact

- 代码：`LandscapeVoiceLifecycleBinder`（竖屏 `routeCurrent` 门闩）、可能触及 `syncLandscapeVoiceLifecycle` / `LandscapeVoiceController` deactivate·activate / `SherpaLandscapeWakeWord` stop vs pause。
- 用户：竖屏下开关喂养玻璃 sheet / 确认框不再卡顿；唤醒模型保持热态。
- 风险：若误把「登录等 PageRoute」也忽略，可能后台继续听麦——设计须只豁免 Overlay，保留 Page 级 deactivate。
- 与主壳 resume HTTP、玻璃 blur 无关；本变更不改 resume bundle。

## 1. Surface want 与 deviceNo listen

- [x] 1.1 在 `LandscapeVoiceController`（或 sync 路径）记录 `_surfaceWant`：want=true 置位，want=false 清除（与 deactivate 一致）
- [x] 1.2 `ref.listen(deviceNoNotifierProvider)`：空→非空且 `_surfaceWant && !_active` 时以 soft-check 补 `activate`
- [x] 1.3 确认与既有 `_active` / `_activateInFlight` 单飞兼容，离表面后 dn 到达不误开

## 2. 点球兜底

- [x] 2.1 `onListenChipTap`：会话未激活且 dn 已非空时尝试补 activate / 麦权路径，勿无操作

## 3. 校验

- [x] 3.1 已绑定冷启：短暂或不再永久停在「绑定宝宝」；dn 就绪后进唤醒或 micDenied
- [x] 3.2 真未绑定：仍显示绑定提示；补绑后自动或点球可激活
- [x] 3.3 `openspec validate prediction-voice-reactivate-on-device-no --strict`

## 1. 几何与状态

- [x] 1.1 为语音圆 `Container` 增加 `GlobalKey`，实现 `_hitInsideVoiceOrb(Offset global)`（圆半径 66 + 可选 slop）
- [x] 1.2 增加 `_slideToCancel`，在 `_voiceHoldActive || _listening` 时由 `onPointerMove` 更新

## 2. 指针处理

- [x] 2.1 扩大底部按住期的 `Listener`（`translucent`），绑定 `onPointerMove` / 统一 `onPointerUp` / `onPointerCancel`
- [x] 2.2 `onPointerUp`：`_slideToCancel` 时走 `_onVoiceCancel`，否则 `_onVoiceEnd`；重置 `_slideToCancel`
- [x] 2.3 准备/连接阶段滑出后松手：不得 `sendCommand`（与 `_voiceHoldSeq` 协同）

## 3. UI

- [x] 3.1 取消态：文案「松开取消」，圆边框用 `error`（或等价）；圆内恢复「松开结束」与原边框色
- [x] 3.2 取消时清空 `_partial`（`_onVoiceCancel` 已有逻辑确认）

## 4. 验证

- [x] 4.1 按住 → 滑出圆 → 显示松开取消 → 松手不发指令
- [x] 4.2 按住 → 滑出 → 滑回圆内 → 松开结束 → 正常发送
- [x] 4.3 云端模式下行为与 Vosk/系统一致

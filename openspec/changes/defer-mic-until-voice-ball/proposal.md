## Why

预测语音在「表面可见」时经 `syncLandscapeVoiceLifecycle` → `activate` → `ensureLandscapeMicPermission`，会立刻弹出用途框与系统麦克风申请。未主动使用语音的用户一进主壳竖屏或预测横屏就被打断，体验差且不符合「点了才要麦」的预期。需改为：表面可见只检查是否已授权；未授权不弹框；仅用户点竖屏语音球 / 横屏监听 chip 后才走用途框与系统申请。

## What Changes

- **表面可见 soft-check**：`activate` / lifecycle 路径仅用已授权探测（如 `landscapeMicAlreadyGranted`），**不得**展示用途框或调用 `Permission.microphone.request` / `hasPermission(request: true)`。
- **手势才 request**：首次需要麦的用户手势（竖屏 `PredictionVoiceEdgeDock` / 横屏 listen chip 的 `onListenChipTap`）才调用完整 `ensureLandscapeMicPermission`。
- **已授权不变**：若进表面时已授权，仍按现有路径启动本地唤醒监听（及既有会话逻辑）。
- **未授权时通道预热（B2）**：未授权 soft activate 仍可在已绑定 `deviceNo` 时建立/复用 `/voice/chat/ws`，但 **MUST NOT** 启动 KWS / 麦克风采集；授权成功后再启唤醒监听。
- **规格 delta**：将「进入预测横屏且未授权 → 立即用途框」改为「首次点监听入口且未授权 → 用途框」；竖横统一。
- **非 BREAKING API**：无后端契约变更；仅客户端权限时机与规格场景变更。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `prediction-landscape-voice`：麦克风用途框与系统申请的触发从「进入预测语音表面」改为「首次点监听入口」；表面可见仅 soft-check；未授权时可预连 chat WS 但不得开麦/KWS。
- `prediction-portrait-voice-dock`：明确竖屏球为授权手势入口之一；表面可见 activate 不得因未授权而弹麦权（与 soft-check 对齐）。

## Impact

- **Flutter**：`landscape_mic_permission.dart`、`landscape_voice_provider.dart`（`activate` / `_activateBody` / `syncLandscapeVoiceLifecycle` / `onListenChipTap`）、主壳竖屏 binder 与横屏预测页 binder 行为语义。
- **规格**：基线 `prediction-landscape-voice` 中「未授权时先弹用途框」等 Scenario；竖屏 dock 中与「activate 即要麦」隐含冲突的表述。
- **无**：Go API、Manifest 声明、iOS `NSMicrophoneUsageDescription` 文案（用途说明弹框文案可微调为「点击后才会使用麦克风」，非强制）。
- **风险**：未授权用户进页后无法 KWS，直到点球；需保证 chip/球在 `micDenied` 时仍可点并弹出用途框。

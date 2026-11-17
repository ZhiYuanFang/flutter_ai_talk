## ADDED Requirements

### Requirement: Portrait surface activate MUST soft-check mic without prompting

When `kPredictionPortraitVoiceEnabled` is true and portrait shell-voice surface want becomes true, the client MUST still call `LandscapeVoiceController.activate` (via `syncLandscapeVoiceLifecycle` or equivalent) per the existing portrait activate requirement, but that activate path MUST only soft-check whether the microphone is already granted. If not granted, the client MUST NOT show the mic rationale dialog and MUST NOT request OS microphone permission solely because the portrait surface became visible. The portrait voice ball tap MUST be a valid trigger for the full rationale + OS request path defined by `prediction-landscape-voice`. 当竖屏 flag 开启且竖屏壳层 surface want 为真时，客户端 MUST 仍按既有要求调用 `activate`，但该路径 MUST 仅 soft-check 麦克风是否已授权；未授权时 MUST NOT 仅因竖屏表面可见而展示用途框或申请系统权限。竖屏语音球点按 MUST 可作为 `prediction-landscape-voice` 所定义的完整用途框 + 系统申请触发入口。

#### Scenario: 竖屏进表面未授权不弹麦权

- **WHEN** `kPredictionPortraitVoiceEnabled == true`，用户处于主壳竖屏语音表面，且麦克风尚未授权
- **THEN** 客户端 MUST 调用 `activate`（含经 lifecycle）
- **AND** MUST NOT 展示麦克风用途说明弹框
- **AND** MUST NOT 发起系统麦克风权限申请

#### Scenario: 点竖屏球才可申请

- **WHEN** 用户点按竖屏预测语音球，且麦克风尚未授权，且本会话未处于拒绝熔断
- **THEN** 客户端 MUST 展示用途说明弹框（确认后发起系统申请）
- **AND** MUST NOT 在用户确认前直接发起系统申请

## MODIFIED Requirements

### Requirement: 麦克风权限 MUST 先用途说明再系统申请

Before the first microphone access needed for prediction wake listening (or dialogue uplink) when permission is not yet granted, the client MUST show an in-app rationale dialog explaining the microphone purpose (wake phrase and voice dialogue transcription; not background recording), and MUST request the OS microphone permission only after the user confirms. That first access MUST be triggered by an explicit user tap on the landscape listen chip or the portrait prediction voice ball (or equivalent listen affordance), NOT merely by the prediction voice surface becoming visible or by `syncLandscapeVoiceLifecycle` / `activate` on surface want. When the surface becomes visible and permission is not granted, the client MUST only perform a non-prompting grant check (status / `hasPermission(request: false)` or equivalent), MUST NOT show the rationale dialog, and MUST NOT call OS permission request APIs. If the user cancels the rationale or the OS denies permission, the client MUST NOT start wake listening and MUST surface a clear status on the listen affordance. If permission is already granted at surface entry, the client MUST skip the rationale dialog and MAY start wake listening per the always-on wake requirement. 当预测唤醒监听（或对话上送）首次需要麦克风且尚未授权时，客户端 MUST 先展示应用内用途说明弹框（说明含：唤醒词与语音对话转写；非后台录音），仅在用户确认后再请求系统麦克风权限。该首次访问 MUST 由用户点按横屏监听 chip 或竖屏预测语音球（或等价监听入口）触发，MUST NOT 仅因预测语音表面可见或 lifecycle/`activate` 表面 want 而触发。表面可见且未授权时，MUST 仅做不弹框的已授权探测，MUST NOT 展示用途框，MUST NOT 发起系统权限申请。用户取消用途框或系统拒绝时，MUST NOT 启动唤醒监听，并 MUST 在监听入口给出可读状态。若进表面时权限已授予，MUST 跳过用途框，并 MAY 按常驻唤醒要求启动监听。

#### Scenario: 表面可见未授权不弹框

- **WHEN** 用户进入预测横屏或主壳竖屏语音表面，且麦克风尚未授权
- **THEN** 客户端 MUST NOT 展示应用内用途说明弹框
- **AND** MUST NOT 发起系统麦克风权限申请
- **AND** MUST 在监听入口给出需要麦克风、可点按的状态（或等价可读提示）

#### Scenario: 点监听入口未授权时先弹用途框

- **WHEN** 用户点按横屏监听 chip 或竖屏预测语音球，且麦克风尚未授权，且本会话未处于「已拒绝不再硬弹」熔断
- **THEN** 客户端 MUST 先展示应用内用途说明弹框
- **AND** MUST NOT 在用户确认前直接弹出系统麦克风权限框（或等价地 MUST NOT 在未确认时发起系统申请）

#### Scenario: 确认后申请系统权限

- **WHEN** 用户在用途说明弹框中确认继续
- **THEN** 客户端 MUST 发起系统麦克风权限申请
- **AND** 若用户授予权限，客户端 MUST 启动本地唤醒监听

#### Scenario: 取消用途框

- **WHEN** 用户在用途说明弹框中取消
- **THEN** 客户端 MUST NOT 启动本地唤醒监听
- **AND** 监听入口状态文案 MUST 提示需要麦克风权限才能语音唤醒

#### Scenario: 进表面已授权跳过用途框

- **WHEN** 用户进入预测语音表面且麦克风权限已授予
- **THEN** 客户端 MUST NOT 展示用途说明弹框
- **AND** MUST 可按常驻唤醒要求启动本地唤醒监听

## ADDED Requirements

### Requirement: Ungranted soft activate MAY prepare chat WS without microphone

When prediction voice surface want is true, `deviceNo` is bound, and the microphone is not yet granted, the client MAY establish or reuse the `/voice/chat/ws` connection as part of soft activate, but MUST NOT start on-device wake-word listening and MUST NOT open a microphone capture stream until permission is granted via the listen-affordance path. Soft activate MUST NOT set the session「已拒绝」熔断 flag solely because permission is not yet granted (as opposed to user cancel / OS deny). 表面 want 为真、已绑定 `deviceNo` 且尚未授予麦克风时，客户端 MAY 在 soft activate 中建立或复用 `/voice/chat/ws`，但 MUST NOT 启动本地唤醒监听，MUST NOT 打开麦克风采集流，直至经监听入口授权成功。soft activate MUST NOT 仅因「尚未授权」而置会话拒绝熔断（与用户取消用途框 / 系统拒绝区分）。

#### Scenario: 未授权可预连通道

- **WHEN** 用户进入预测语音表面、已绑定宝宝、麦克风尚未授权
- **THEN** 客户端 MAY 连接或复用 `/voice/chat/ws`
- **AND** MUST NOT 启动对「胖宝」的本地唤醒监听
- **AND** MUST NOT 打开用于唤醒或上行的麦克风采集

#### Scenario: 授权后补启唤醒

- **WHEN** 用户在未授权 soft 会话中经监听入口完成用途框确认并获得系统麦克风授权
- **THEN** 客户端 MUST 启动本地唤醒监听（或等价地进入可听「胖宝」状态）

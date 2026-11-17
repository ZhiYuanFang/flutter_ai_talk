## 1. Soft-check 与 activate 半激活

- [x] 1.1 在 `landscape_mic_permission.dart`（或邻接）明确 soft-check 入口：仅 `landscapeMicAlreadyGranted` / 不弹框不 request；与 `ensureLandscapeMicPermission` 分离
- [x] 1.2 改 `syncLandscapeVoiceLifecycle`：surface want 时注入 soft-check，不得再注入会弹用途框/`request` 的闭包
- [x] 1.3 改 `_activateBody`：soft mic 失败时置 `micDenied` + 可读文案；可预连 `/voice/chat/ws`（B2）；跳过 KWS/`start` 采集；不得仅因「尚未授权」置 `landscapeMicDeniedThisSession`
- [x] 1.4 soft 失败与已授权全量激活、deactivate 路径状态机一致（半激活可 teardown，授权后可补启唤醒）

## 2. 监听入口 full ensure

- [x] 2.1 `onListenChipTap`（竖屏球 / 横屏 chip 共用）：未授权或 `micDenied` 时走完整 `ensureLandscapeMicPermission`；成功后补启唤醒监听（或完整 activate）
- [x] 2.2 确认无其它路径在表面可见时调用会 `request` 的 ensure（搜 `ensureLandscapeMicPermission` / `Permission.microphone.request`）

## 3. 校验

- [x] 3.1 未授权冷启：进主壳竖屏 / 预测横屏不弹用途框与系统麦权；球/chip 显示可点提示
- [x] 3.2 点球/chip：先用途框 → 确认后系统申请 → 授权后可听「胖宝」
- [x] 3.3 已授权用户：进表面仍可常驻唤醒，无多余用途框
- [x] 3.4 `openspec validate defer-mic-until-voice-ball --strict`（若 CLI 可用）

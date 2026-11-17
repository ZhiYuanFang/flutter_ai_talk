## Context

预测语音会话由 `LandscapeVoiceController` 统一驱动：主壳竖屏与预测页横屏经 `syncLandscapeVoiceLifecycle` 在 surface want 为真时调用 `activate(ensureMic: …)`。当前注入的始终是 `ensureLandscapeMicPermission`（用途框 + `Permission.request` / `record.hasPermission(request: true)`），因此一进表面就会弹权。`onListenChipTap` 仅在已 `micDenied` 时再走同一路径重试。

基线 `prediction-landscape-voice` 明确「进入预测横屏且未授权 → 用途框」，与产品现诉求冲突。探索结论采用方案 **B + B2**：表面可见只 soft-check；手势才 request；未授权仍可预连 chat WS。

## Goals / Non-Goals

**Goals:**

- 竖屏 / 横屏统一：surface 可见 → soft-check；点球/chip → 完整用途框 + 系统申请。
- 已授权用户体验不变（进表面即可 KWS）。
- 未授权：可读 `micDenied` 状态、可点重试；可预连 `/voice/chat/ws`，不开麦/不启 KWS。
- 规格与实现一致，改写「进横屏即弹用途框」场景。

**Non-Goals:**

- 不改唤醒词、PCM、chat WS 协议、TTS/barge-in 主路径。
- 不改 AndroidManifest / iOS Info.plist 声明本身。
- 不恢复喂养页大语音球；不引入第二套权限 UI。
- 不做 Web 麦克风（既有 `kIsWeb` 短路保留）。

## Decisions

### D1：lifecycle 注入 soft-check，手势注入 full ensure

- **做法**：`syncLandscapeVoiceLifecycle` 传入「仅 `landscapeMicAlreadyGranted`（或薄封装 `ensureMicIfAlreadyGranted`），失败返回 false」；`onListenChipTap`（及任何「首次需要麦」的点按）传入 `ensureLandscapeMicPermission`。
- **备选 A（延后到点球才 activate）**：未点前不 activate → 与「竖屏 flag 开 MUST activate」冲突，首轮通道更慢。
- **备选 C（仅竖屏延后）**：横竖两套语义，规格碎。弃用。

### D2：未授权 soft activate = B2 通道预热

- **做法**：`_activateBody` 在 soft mic 失败时：置 `micDenied` + 提示文案；**仍** `_active`（或等价「半激活」）并 `chat.connect()`；**跳过** `_wake!.start` / 任何 `request: true` 采集。授权成功后（chip 路径）再启 KWS。
- **备选 B1（全挡）**：实现更短，但与「进入即准备通道」基线更远，首轮点听更慢。弃用。
- **实现注意**：需避免 soft 失败时把 `landscapeMicDeniedThisSession` 置 true（那是用户取消用途框 / 系统拒后的会话熔断）；soft 未授权只是「尚未询问」。

### D3：`activate` 入参语义拆清

- 保留 `ensureMic` 回调，由调用方决定 soft vs full；或增加命名参数 `requestIfNeeded`。倾向**调用方注入不同闭包**，少改 controller 签名面。
- chip 在 `micDenied` 时：清会话拒绝标记 → full ensure → 成功则启 KWS（若已半激活则 `start` wake；若之前因旧逻辑未 `_active` 则走完整激活）。实现以「授权后必达 listening/唤醒就绪」为准。

### D4：用途框文案

- 可保留现有标题/说明；可选补一句「仅在你点击语音入口后才会申请」。非阻塞；若改文案不引入新 tag。

## Risks / Trade-offs

- **[Risk] soft 半激活与现 `_active` 布尔纠缠** → Mitigation：明确「未授权半激活」状态机（`_active && micDenied` 或显式 phase），`deactivate` / 方向切换仍统一 teardown。
- **[Risk] 未授权用户以为「没开语音」** → Mitigation：球旁/chip 保留「需要麦克风…点按」类文案；点按必出用途框（除非本会话已拒且需再次点按清标记——沿用现逻辑）。
- **[Risk] 预连 WS 无麦产生多余连接** → Mitigation：与「进横屏即准备通道」一致；离开 surface 仍 `deactivate` 断开；可接受。
- **[Trade-off] 新用户无法「免手势」被唤醒** → 产品接受；已授权老用户不受影响。

## Migration Plan

- 纯客户端行为变更，无数据迁移。
- 回滚：lifecycle 恢复注入 `ensureLandscapeMicPermission` 即可回到进表面弹权。

## Open Questions

- （无阻塞）用途框文案是否微调：实现时可按产品一句话决定，默认保留现文案。

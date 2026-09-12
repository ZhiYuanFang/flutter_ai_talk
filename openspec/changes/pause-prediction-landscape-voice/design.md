## Context

竖屏预测语音已由 `kPredictionPortraitVoiceEnabled = false` 暂停。横屏仍经 `_LandscapeVoiceLifecycleBinder` → `syncLandscapeVoiceLifecycle` → `LandscapeVoiceController.activate` 启动 KWS + `/voice/chat/ws`，并展示左下监听 chip 与字幕。对话模型未就绪，需对称暂停整条横屏助手（方案 B），而非仅关唤醒词。

## Goals / Non-Goals

**Goals:**

- 横屏：无 binder activate、无 chip、无字幕；不因进横屏预测要麦 / 下 KWS。
- 竖屏：继续仅受既有 portrait flag 控制（默认仍关）。
- 一处编译期 flag，注释写明原因与翻回方式。

**Non-Goals:**

- 不删除 `landscape_voice_provider` / wake / chat 实现。
- 不改 KWS CDN、chat WS 协议、远场采集配置。
- 不关喂养页语音；不做「仅关 KWS、保留点按联调」。

## Decisions

### D1：独立横屏 flag（对称竖屏）

**选择**：`kPredictionLandscapeVoiceEnabled = false`，与 portrait 并列于 `ucg_feature_flags.dart`。

**替代**：单一 `kPredictionVoiceAssistantEnabled` — 可后续合并；本刀保持与已落地竖屏 pause 对称，便于分别翻回。

### D2：UI 与 lifecycle 双闸

**选择**：

1. 横屏 Stack：**仅当** `kPredictionLandscapeVoiceEnabled` 为 true 时挂载 binder、chip、字幕。
2. `syncLandscapeVoiceLifecycle`：`want` 增加 `&& kPredictionLandscapeVoiceEnabled`。
3. `landscapeVoice` watch：`(isLandscape && kPredictionLandscapeVoiceEnabled) || kPredictionPortraitVoiceEnabled`。

**理由**：只藏 UI 仍可能被别处 activate；只改 sync 仍可能空挂 chip。

### D3：不改 provider 内部状态机

**选择**：flag 关时不 enter activate；实现代码保留。翻 `true` 即恢复既有行为。

## Risks / Trade-offs

- **[Risk] 漏闸别处 activate** → sync + 不挂 binder 双保险。  
- **[Trade-off] 两开关** → 比单开关多一行；翻回更灵活。  
- **[Risk] 注释仍写「横屏不受竖屏开关影响」过时** → 同步改 portrait flag 旁注。

## Migration Plan

1. 发版默认横屏语音不可见。  
2. 模型就绪：`kPredictionLandscapeVoiceEnabled = true`（竖屏另翻）。  
3. 回滚：同翻 true 或 revert 本 change。

## Open Questions

（无）

## Context

竖屏预测底部已有 `PredictionGoRecordFab`（短按切喂养）。横屏对话由 `LandscapeVoiceController` + `VoiceChatWsClient`（`/voice/chat/ws`）承担：页可见预连、KWS「胖宝」、ding、PCM 上行、服务端静音 commit、TTS 播报。竖屏贴边球（`PredictionVoiceEdgeDock`）由 `kPredictionPortraitVoiceEnabled` 门控，当前为 false，但基础版墙仍经 `predictionVoiceEngageRequestProvider` 指向 engage。Go 已支持 `start.outputModality=text|audio`；App 未发送该字段，且话轮收口依赖 `audio_end`。

约束：鉴权业务 WS 例外外，语音 chat 继续用既有 `VoiceChatWsClient`；`app/lib` 日志走 `AppDebugLog`；弹框麦权沿用横屏用途框节奏（由显式手势触发）。

## Goals / Non-Goals

**Goals:**

- 竖屏以 FAB 长按 PTT 完成「类语音球」记录/查询，无需唤醒。
- 竖屏 text 出、横屏 audio+TTS；旋转可切换 modality。
- 删除竖屏贴边球与 portrait flag，消除双入口。
- 基础版原语音球卡改为 FAB 心跳 3 次指引。

**Non-Goals:**

- 不改 Go TTS/协议（仅消费已有 modality）。
- 不改横屏 KWS / 麦芯 / 多轮续听主路径（除旋转撕会话与 start modality）。
- 不复活喂养页大语音球；不以 `/voice/asr/ws` 作为本入口。
- 不做按住教学自动开麦；心跳仅吸引注意。
- 不播退场音 `wo_xian_tui_xia_le`（竖屏 PTT）。

## Decisions

### 1. 抽出无唤醒 hold API，而非整页复用 activate+KWS

- **选择**：在编排层增加 `startHold` / `endHold(cancel:)`（名称以实现为准），内部复用 `VoiceChatWsClient`；竖屏表面只预连、不启 KWS。
- **理由**：横屏 `activate` 绑定唤醒与 idle 续听，与 PTT「松手收口」语义冲突。
- **备选**：FAB 直调 client（易漏麦权/字幕/旋转）；或打开 portrait flag（与删球目标相反）。

### 2. 页可见预连，长按才开麦

- **选择**：预测竖屏表面可见 → `connect()`；长按阈值达成 → ding + `ensureSessionStarted(outputModality: text)` + `beginListen`。
- **理由**：PTT 冷启动建连延迟会吃掉首句。
- **备选**：完全按需建连（体验差）。

### 3. 松手唯一业务 commit；按住期抢先 commit 忽略

- **选择**：holding 期间忽略服务端 `interrupt_commit` 对业务收口的影响；松手调用 `commitUtterance()`（已有、现未使用）。cancel 则停麦不 commit。
- **理由**：PTT 边界由手指定义，避免双答/提前收口。
- **备选**：承认服务端抢先答完（实现简单但手感飘）。

### 4. 滑出取消用 pill 外扩容错区

- **选择**：keep 区 = pill bounds inflate ~32 logical px（常量可调，建议 24–40）；仅指针落在 keep 区外视为取消态；松手时若取消则 cancel。
- **理由**：避免擦到 pill 描边误取消；旧喂养球是半径+slop 的同类思路。
- **备选**：严格 pill 命中（误触高）。

### 5. 按会话 `outputModality`，旋转硬撕

- **选择**：每次 `start` 读当前方向：`portrait→text`，`landscape→audio`。方向变化：取消 hold/进行中轮次 → `endSession` → 按新表面模式重绑（竖屏预连无 KWS / 横屏 activate+KWS）。text 模式在 `answer`（含 `finish_talk`）后 seal `TurnEnded`，不得死等 `audio_end`。
- **理由**：Go modality 绑在 `start`；同连接 `end`→`start` 即可切换。进行中轮次不保证旧 modality 播完。
- **备选**：等本轮结束再切（旋转后可能仍播 TTS）。

### 6. 删除竖屏球；字幕独立挂载

- **选择**：移除 `kPredictionPortraitVoiceEnabled`、`PredictionVoiceEdgeDock` 挂载、`predictionVoiceEngageRequestProvider`；竖屏字幕在预测页/壳按 `LandscapeVoiceSubtitleToast` 独立展示（不跟已删球）。
- **理由**：竖屏入口唯一化为 FAB，避免 flag 与预连打架。

### 7. 基础版墙 → FAB pulse request

- **选择**：新 `predictionGoRecordFabPulseRequestProvider`（token 模式对齐投屏 request）；关墙后 FAB 心跳 Scale×3，不清自动开麦。条目文案改为长按记录导向；demo 可弱化为 pill/mic 示意。
- **备选**：保留 engage 请求名（误导）。

### 8. 双势手势

- **选择**：pointer 模型：短于长按阈值抬起 → 短按切喂养；超过阈值仍按下 → 进入 PTT（触感）；PTT 中跟滑判断取消态。
- **理由**：`InkWell.onLongPress` 无松手 commit。

## Risks / Trade-offs

- [长按阈值内已开口] → 文案强调「长按」；阈值后 ding 再说话；可后续加触感。
- [服务端抢先 commit 与客户端再 commit] → holding 丢弃抢先业务收口；松手再 commit；空转写走既有无结果路径。
- [与横屏共用 `voiceChatWsClientProvider`] → 旋转/离页必须 `endSession`；禁止双模式同时认为在听。
- [text 模式漏改 seal] → 验收：无 `audio_*` 时必须能出字幕并结束轮次。
- [删除 portrait dock 与基线「发版默认 true」冲突] → 本变更 REMOVED/改写该能力，归档后基线不再要求竖屏球。

## Migration Plan

1. 实现 hold API + modality/seal + FAB 手势与文案。
2. 竖屏预连 lifecycle；挂字幕 toast。
3. 删球/flag/engage；墙改 pulse + 文案。
4. 横屏回归：唤醒、TTS、续听仍可用；旋转后 modality 正确。
5. 回滚：恢复 flag/dock 挂载与 engage（高成本）；更现实是 feature 开关仅关 FAB PTT。

## Open Questions

- 容错 inflate 最终常量（默认 32）是否需设计稿确认——实现用命名常量即可调。
- PTT 成功出 answer 后是否保持 WS 预连（默认：保持预连，end 音频会话窗按既有 `waitEndAfterCommit` / round restart）——采纳保持预连。

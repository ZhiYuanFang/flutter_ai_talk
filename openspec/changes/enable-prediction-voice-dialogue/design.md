## Context

预测页语音对话已完整实现（`LandscapeVoiceController` + 横屏 chip + 竖屏 `PredictionVoiceEdgeDock`），被 `ucg_feature_flags.dart` 中两个编译期常量默认 `false` 关掉。基线规格（`prediction-landscape-voice` / `prediction-portrait-voice-dock`）已允许 flag=`true` 恢复；竖屏 binder 虽可挂载，但 `syncLandscapeVoiceLifecycle` 的 `want` 条件硬编码 `landscape && kPredictionLandscapeVoiceEnabled`，导致竖屏开启后 UI 有、会话不 `_active`。

对照基线：`openspec/specs/v2.1.3.md`。鉴权业务 WS 仍走既有 `ResilientWebSocketClient`；语音 chat 沿用现有 `VoiceChatWsClient`；ASR 填框栈不在范围。

## Goals / Non-Goals

**Goals:**

- 竖屏与横屏预测语音对话产品默认开启。
- 竖屏与横屏在「预测页可见 ∩ 对应方向 flag 开 ∩ 非 Web Android/iOS」时均可 `activate`。
- 保留两把独立 flag，便于日后单方向紧急关闭。

**Non-Goals:**

- 不改 KWS 词、chat WS 协议、字幕/贴边球交互契约。
- 不接入成长轨迹 / 喂养页 ASR 按住说话。
- 不在 Web 开启；不要求后台常听。
- 不改麦克风用途说明文案的产品语义（仍先 rationale 再系统权限）。

## Decisions

### 1. 默认双开 flag，保留 gate 语义

- **选择：** `kPredictionLandscapeVoiceEnabled = true`、`kPredictionPortraitVoiceEnabled = true`；注释改为「默认开启；翻 `false` 可紧急关闭」。
- **理由：** 产品要求竖+横一并放开；规格中 gate requirement 仍有价值（回滚只需改常量）。
- **备选：** 删除 flag、永远开启 → 否决（失去单方向熔断）。

### 2. Lifecycle `want` 按方向 OR

- **选择：**  
  `want = !kIsWeb && predictionVisible && (Android|iOS) && ((landscape && landscapeFlag) || (!landscape && portraitFlag))`
- **理由：** 与 UI 挂载条件对齐；竖屏不再依赖「把 landscape 传成 true」的注释技巧。
- **备选：** binder 竖屏传 `landscape: true` → 否决（语义撒谎，易与真实 orientation 分支冲突）。

### 3. 共用既有 Controller，不新建会话栈

- **选择：** 继续单一 `landscapeVoiceControllerProvider`。
- **理由：** 竖/横只是入口形态不同，会话/KWS/chat/TTS 已共用。

## Risks / Trade-offs

- **[Risk] 对话模型线上质量不稳** → 任一方向可单独翻 flag=`false` 紧急关表面。
- **[Risk] 竖屏 activate 后与横屏切向竞态** → 既有 deactivate-on-leave 路径；切 orientation 时 binder 重入 sync，保持单飞行 activate/deactivate。
- **[Trade-off] 默认开麦入口** → 仍走既有用途说明 + 权限；首次进入才会弹。

## Migration Plan

1. 改 flag 默认值 + lifecycle 条件，热重载/重装即可验证。
2. 回滚：两常量改回 `false`（或只关有问题的方向），无需数据迁移。

## Open Questions

- （无）产品已确认方案 A：竖+横一并默认开启。

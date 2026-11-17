## Context

`predict-basic-tier-demos` 已将基础版墙做成「文案 + 中档 demo」，且 demo `IgnorePointer`、不可导航。explore 后产品要求：弱化「小智」品牌；整行可点进入真实能力；语音球关墙后贴边 engage；投屏关墙后复用现有确认。

## Goals / Non-Goals

**Goals:**

- 音箱条：标题「家中音箱 · 免动手」+ 实体音箱/脱离手机/纯语音副标题；角标「可付费开通」不变。
- 行级 tap：先 `Navigator.pop` 关墙，再按 kind 落地。
- 投屏：复用预测页「进入投屏模式」glass confirm → 锁横屏（同一文案与埋点语义）。
- 语音球：关墙后 peek → **edgeEngaged 全圆仍贴边**（不 `showFloating`）。
- 家庭共享：不跳转路由。

**Non-Goals:**

- 不改设置页「小智音箱」标题/开通流。
- 不把球浮空到屏心；不自动开始听写。
- 不做 Pro 行跳转；不改 Go / Android 原生。

## Decisions

1. **点击落点**  
   整行 `InkWell`/`GestureDetector`；demo 保持 `IgnorePointer`，避免与行手势抢。  
   替代：demo 也可点——拒绝，demo 仍是示意，业务只走行。

2. **关墙再动作**  
   `await pop`（或 `pop` + post-frame）后再 `context.push` / 发 request，避免目标页叠在墙 Dialog 上。

3. **落地表（kind → 动作）**

   | kind | 动作 |
   |------|------|
   | nextEstimate | 仅关墙 |
   | pushRemind | `/settings/notifications` |
   | homeWidget | `/widgets/showcase` |
   | familyShare | 仅关墙（不跳转） |
   | landscapeCast | request → 预测页弹投屏确认 |
   | voiceBall | request → 语音球 `showEngaged` |
   | trendChart | `/trends` |
   | xiaozhiSpeaker | `/settings/xiaozhi-speaker` |

4. **投屏桥**  
   抽出与 IconButton 同源的 confirm + `_lockPredictionLandscapeCast` + usage event；用一次性 request provider（类比 `homePagerRequestProvider`），`smart_prediction_screen`（或壳在预测页可见时）listen 消费后 clear。  
   替代：墙内直接锁横屏——拒绝，须保留用户确认。

5. **语音球 engage 桥**  
   `EdgeDockController` 新增 `showEngaged()`（内部走现有 `_engage`，不触发 `onPullBusiness` 自动听写）。  
   `PredictionVoiceEdgeDock` 暴露/listen request；收到后对当前 edge/along 做 engage。  
   若已 floating：可不强制改回贴边（本版以「仍贴边」为目标；已浮空则可 no-op 或保持浮空——实现选 **已 floating 则 no-op**）。

6. **与 demos 规格关系**  
   覆盖「点 demo 不导航」：demo 区仍不单独导航；**行**允许导航。实现与手测以本 change 为准。

## Risks / Trade-offs

- [墙已关、预测页未挂载] → 投屏/语音 request 丢失：消费方在 shell 或预测页 listen，关墙后预测页仍在底层，通常仍挂载。  
- [engage 误触发听写] → `showEngaged` MUST NOT 走 `onPullBusiness`。  
- [家庭共享无落地页] → 接受仅关墙；文案仍描述能力。

## Migration Plan

- 纯客户端；回滚恢复旧文案与不可点行即可。

## Open Questions

- （无）explore 已锁定标题 C、家庭不跳、投屏确认、贴边 engage、角标不改。

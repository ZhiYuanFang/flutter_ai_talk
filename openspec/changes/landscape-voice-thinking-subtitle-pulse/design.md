## Context

横屏弹幕 `_LandscapeVoiceSubtitleToast` 仅收 `text`，字色统一满对比。`LandscapeVoiceController` 已维护 `thinking` 与 `subtitle`，但 UI 未用角色区分。产品要：思考态更浅 + 慢弱 opacity 脉冲；答案落地后稳定满对比。

## Goals / Non-Goals

**Goals:**

- 显式弹幕角色传到 toast（推荐 enum / bool `isThinking`）。
- 思考：muted 字色 + 慢弱循环脉冲。
- 非思考（答案、ASR、「我在」等）：满对比、无脉冲。

**Non-Goals:**

- 不改 thinking `\r` 分段、WS、idle。
- 不加「思考中」前缀（除非实现时极便宜且不破坏换行，默认不做）。
- 不新建 AppColor token（用既有 `textOnPanelGlass` / `Muted`）。

## Decisions

1. **状态**  
   增加 `LandscapeVoiceSubtitleKind { none, asr, thinking, answer }` 或至少 `subtitleIsThinking`。  
   - `thinking_delta` → thinking  
   - `answer` → answer  
   - ASR partial/final、「我在」→ asr（或 neutral，**不脉冲**）  
   - clear → none  

2. **浅色**  
   思考正文：`AppColor.textOnPanelGlassMuted`；答案/ASR：`textOnPanelGlass`（可略保留现有 0.95）。  
   备选整条降 opacity → 否决为主手段（与脉冲叠乘易过淡）。

3. **脉冲**  
   `AnimationController` repeat reverse；周期约 **1.2–1.8s**；opacity 约在 **0.55–1.0**（或 0.65–1.0）弱幅。仅 `kind==thinking` 时跑；切换 kind 时 stop/reset。  
   可叠在现有挂载淡入之外：思考脉冲包一层 `FadeTransition`/`AnimatedBuilder`。

4. **换字**  
   思考阶段换字不重启脉冲相位（避免闪）；仅 kind 切入 thinking 时 start。

## Risks / Trade-offs

- [浅壳 muted 对比不足] → 真机看两套主题；必要时略提高下限 opacity。  
- [脉冲晕动] → 保持慢弱；支持减少动效系统设置时可停脉冲（若项目已有，对齐；否则本期可不接）。  
- [kind 推断用 thinking==subtitle] → 脆弱；坚持显式字段。

## Migration Plan

1. provider 写 kind → toast 接参 → 脉冲。  
2. 真机：思考浅+脉冲；答案满对比停脉冲。  
3. 回滚删 kind/脉冲即可。

## Open Questions

- （无）浅字 + 轻脉冲已确认；前缀文案不做。

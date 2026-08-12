## Why

横屏语音弹幕对 ASR、思考、答案使用同一套满对比字色，用户难以区分「仍在思考」与「最终回复」。需要在思考态用更浅字色，并加慢而弱的 opacity 脉冲，让「正在想」可感知；答案到达后恢复稳定满对比。

## What Changes

- `LandscapeVoiceUiState`（或等价）暴露弹幕角色：至少区分 `thinking` vs 非思考（ASR/答案/提示）。
- `_LandscapeVoiceSubtitleToast`：思考态字色用 `AppColor.textOnPanelGlassMuted`（或文档化等价浅字）；非整条硬编码灰。
- 思考态：慢、弱的循环 opacity 脉冲；答案/ASR/清空时停止脉冲并恢复稳定满对比（`textOnPanelGlass`）。
- 不改 WS、`\r` 分段、idle/end 契约；不强制加「思考中」前缀文案（可选后续）。

## Capabilities

### New Capabilities

- `landscape-voice-thinking-subtitle`：横屏语音弹幕在思考态的浅字色与轻脉冲反馈。

### Modified Capabilities

- （无）基线未收录弹幕角色样式；主题底由并行/已完成的 `landscape-voice-subtitle-theme` 约束，本变更只加思考态表现。

## Impact

- `landscape_voice_provider.dart`：设置/清除 `subtitleKind`（或布尔 `subtitleIsThinking`）。
- `smart_prediction_screen.dart`：toast 按角色取色与脉冲。
- 颜色必须经 `AppColor.*`，禁止内联马卡龙 hex。

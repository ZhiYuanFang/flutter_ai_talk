## Why

预测横屏语音字幕弹幕底色写死半透明黑，换主题后对比与品牌感不一致；左下监听 chip 已部分走 `panelGlass`，与弹幕未成套。用户需要弹幕（及配套 chip）随主题色变化，并轻微提升出现观感。

## What Changes

- `_LandscapeVoiceSubtitleToast`：去掉 `Colors.black` 硬编码底；底/字/描边经 `AppColor.panelGlass*` / `textOnPanelGlass*`（或文档化等价原子）取色。
- `_LandscapeVoiceListenChip`：与弹幕统一浮层语言（panelGlass + onPanelGlass）；连接指示点改为主题语义色（如 `colorScheme.error` / 成功向主题色），禁止业务内联马卡龙 hex（除非注释标明的信号色例外并尽量收敛）。
- 轻微 UI 优化：弹幕出现淡入（短时长）、圆角与 padding 与 chip 族对齐；不改字幕生命周期（播完清 / idle 等由既有 voice change 负责）。
- **不**改 WebSocket / 唤醒 / finish_talk 逻辑。

## Capabilities

### New Capabilities

- `landscape-voice-overlay-theme`：横屏语音弹幕与监听 chip 的主题语义取色及轻量出现动效。

### Modified Capabilities

- （无）合并基线 `v2.1.0` 未收录横屏语音 overlay 细则；布局/消失语义仍由进行中的 `landscape-voice-no-result-subtitle` / listen-chip changes 约束，本变更只补主题与轻观感。

## Impact

- `app/lib/ui/smart_prediction_screen.dart`（`_LandscapeVoiceSubtitleToast`、`_LandscapeVoiceListenChip`）。
- 依赖既有 `AppColor` / `AppVisualTokens`；原则上不新增 token，除非现有原子无法表达连接点「成功」色（若新增须三联文档，本变更优先用 `ColorScheme` 语义色避免扩 token）。
- 真机：切换主题调色板后弹幕/chip 底字对比可读；浅/暗壳均无近白底配白字。

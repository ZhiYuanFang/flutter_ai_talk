## Why

语音模式下，底部 220px 区在「聆听中…」、服务端回复预览与实时转写之间分工不清：按住即占用约 52px 字幕槽，语音球被挤下；转写已在历史上方的转写条展示，回复却仍挤在底栏，与「上方消息带、下方纯操作区」的产品预期不一致。需将语音相关的全部可读文案统一到历史上方的同一条可伸缩区域，底栏仅保留语音球与手势，保证球位置恒定。

## What Changes

- **统一语音消息条**：在「历史 `Expanded`」与底栏之间，用一条可伸缩 strip 展示语音模式下的可读文案；优先级为 `_chatReply`（非空）→ `_partial`（非空）→ 不显示 strip。
- **取消「聆听中…」**：语音模式按住/连接/开录期间不得再于底栏或 strip 显示「聆听中…」占位文案；无 partial、无 reply 时 strip 隐藏。
- **底栏语音区固定**：语音模式底栏 220px 内不得再插入 `HomeInputCaption`（无 `Column(字幕 + Expanded(球))`）；语音球垂直位置在按住、出 partial、收回复全过程中保持不变。
- **服务端回复上移**：`_chatReply` 在语音模式下于 strip 多行展示（沿用转写条高度上限与滚动规则）；长回复在 strip 上可点击展开 BottomSheet（迁移 `home-caption-expand-reply` 的语音路径）。
- **文字模式不变**：文字输入通道仍可在底栏使用 `HomeInputCaption` 展示服务端回复与点击展开（若当前已有该行为则保持）。
- **与既有转写条合并**：将 `HomeVoicePartialStrip` 泛化为 `HomeVoiceMessageStrip`（或等价命名），同时承载 partial 与 reply，避免两套顶栏组件。

## Capabilities

### New Capabilities

- `home-voice-message-strip`：语音模式统一消息条（partial + 服务端回复）、底栏无字幕槽、回复在 strip 上可展开。

### Modified Capabilities

- `home-voice-partial-push-up`（delta）：转写条扩展为统一消息条；回复不再回到底栏；显示条件与优先级调整。
- `home-input-shared-caption`（delta）：语音模式底栏字幕槽不再用于聆听中、partial 或服务端回复预览。
- `home-caption-expand-reply`（delta）：语音模式下长回复的展开入口改到消息条点击，底栏路径仅保留文字模式（或语音路径移除底栏展开）。

## Impact

- `app/lib/ui/home_screen.dart`（`_showPartialStrip` / `_homeInputCaptionText`、底栏 `Column` 结构、strip 插入条件）
- `app/lib/ui/home_voice_partial_strip.dart`（重命名/泛化为消息条，支持 reply + `onExpand`）
- `app/lib/ui/home_input_caption.dart`、`app/lib/ui/home_reply_bottom_sheet.dart`（展开逻辑复用，调用方调整）
- OpenSpec delta：`home-voice-partial-push-up`、`home-input-shared-caption`、`home-caption-expand-reply` 相关条文

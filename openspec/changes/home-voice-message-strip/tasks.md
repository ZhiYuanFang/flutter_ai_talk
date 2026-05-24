## 1. 消息条组件

- [x] 1.1 自 `home_voice_partial_strip.dart` 演进为 `home_voice_message_strip.dart`（`HomeVoiceMessageStrip`），保留 AnimatedSize、30% 上限、滚动与 partial 滚底
- [x] 1.2 为 reply 模式增加 `expandable` / `onExpand`（可滚动溢出或等价截断判定）与可选 `InkWell`
- [x] 1.3 删除或改为 export 旧 `HomeVoicePartialStrip`，更新 `home_screen` import

## 2. 主页状态与布局

- [x] 2.1 在 `home_screen.dart` 实现 `_voiceStripText`、`_showVoiceMessageStrip`（reply > partial，无「聆听中…」）
- [x] 2.2 用 `HomeVoiceMessageStrip` 替换原 `HomeVoicePartialStrip` 插入点；reply 时传入展开回调
- [x] 2.3 语音模式底栏 `SizedBox(220)` 改为纯 `Stack`（移除 `Column` 顶栏 `HomeInputCaption`）
- [x] 2.4 调整 `_homeInputCaptionText()`：移除语音「聆听中…」；仅文字模式在底栏展示 `_chatReply`
- [x] 2.5 确认 `_applyChatReply`、新一轮按住清空 reply、松手保留 partial 与规格场景一致

## 3. 展开与验证

- [x] 3.1 语音 reply 点击调用 `showHomeReplyBottomSheet`；partial 不注册展开
- [x] 3.2 本地验证：按住无 strip → partial 在条内 → 松手保留 → reply 在条内且球不动 → 长回复展开 → 文字模式底栏回复仍正常

## 4. 聆听中提示（消息条）

- [x] 4.1 按住语音球且尚无 partial 时，在 `HomeVoiceMessageStrip` 显示「聆听中…」（不得占用底栏字幕槽）

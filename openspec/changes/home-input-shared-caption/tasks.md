## 1. 字幕组件

- [x] 1.1 新增 `lib/ui/home_input_caption.dart`：`HomeInputCaption` 固定高度（约 52px）、最多 3 行居中、`ellipsis`
- [x] 1.2 在 `home_screen.dart` 增加 `displayCaption` 推导（回复 > 转写 > 可选「聆听中…」）

## 2. 语音模式

- [x] 2.1 `_buildVoiceOrb`：移除球上/下独立 `_partial`、`_chatReply` 文本，改为 Column 顶部 `HomeInputCaption`
- [x] 2.2 `onPointerDown`：清空 `_chatReply` 与 `_partial` 后再 `startSession`
- [x] 2.3 `_onVoiceEnd`：松手时不再立即 `_partial = ''`；回复到达后写入 `_chatReply` 并可选清空 `_partial`
- [x] 2.4 `_onVoiceCancel`：清空转写展示相关状态

## 3. 文字模式

- [x] 3.1 `_buildTextInput`：输入框上方接入同一 `HomeInputCaption`，移除输入框下方 `_chatReply` 块
- [x] 3.2 `_onTextSubmit` 与语音结束路径共用回复写入逻辑，保证覆盖规则一致

## 4. 验证

- [x] 4.1 云端模式：按住可见转写；松手转写保留；回复到达后同框覆盖；再按住清空
- [x] 4.2 文字模式：提交后回复仅出现在上方字幕框，底部无第二行回复

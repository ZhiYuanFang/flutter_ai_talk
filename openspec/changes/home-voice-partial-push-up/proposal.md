## Why

按住说话时实时转写（`_partial`）在底部固定 52px、3 行字幕槽内被省略，用户看不到完整识别内容。需在**不遮挡语音球**的前提下，让转写区域随内容增高并**向上挤压历史列表**（方案 A），松手后至服务端回复到达前可继续展示最后一帧转写。

## What Changes

- 布局：在「历史 `Expanded`」与「底部固定输入区（约 220px）」之间增加**可伸缩转写条**；仅当存在可展示的 partial 文案时显示。
- 按住聆听（`_listening`）期间：转写条多行展示 `_partial`（不设 3 行上限），高度随内容增长，**上限**为屏高一定比例（如 30%），超出则省略并保留末尾可见（或内部滚动，见 design）。
- 历史区仍为 `Expanded`，转写条占用的高度自动使历史列表变矮（视觉上「往上推」）。
- 底部 220px 区**仅**保留语音球/文字输入、按住手势、响度柱等；**聆听中 partial 不再**占用底栏顶部固定字幕槽（避免压按钮）。
- 松手后、`_chatReply` 到达前：转写条可保留最后一帧 `_partial`；一旦写入服务端回复，转写条隐藏，回复仍走底栏 `HomeInputCaption` + 既有 BottomSheet 展开（`home-caption-expand-reply`）。
- 「聆听中…」且无 partial 时：不显示转写条（或单行轻提示，不占大块高度）。

## Capabilities

### New Capabilities

- `home-voice-partial-push-up`：实时转写顶栏挤压历史、底栏与回复展示分工。

### Modified Capabilities

- `home-input-shared-caption`（delta）：转写预览在聆听期的展示位置与高度规则；底栏字幕槽主要用于服务端回复与无顶栏时的短文案。

## Impact

- `app/lib/ui/home_screen.dart`（`Column` 结构、`_partial` / `_listening` / `_chatReply` 分支）
- 新建 `app/lib/ui/home_voice_partial_strip.dart`（或等价）
- `app/lib/ui/home_input_caption.dart`（聆听中 partial 时不重复展示于底栏槽位）

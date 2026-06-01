## Why

主页底部字幕框（`HomeInputCaption`）固定 3 行高度，服务端 `sendCommand` 返回的长回复（`_chatReply`）常被省略号截断，用户无法阅读完整反馈。需在**仅展示服务端回复**时支持点击，以**底部抽屉**查看全文。

## What Changes

- 当字幕框内容为服务端回复（`_chatReply`）且文本被截断时，字幕区域可点击，打开 **BottomSheet** 展示完整回复（可滚动、可选中复制）。
- 转写预览（`_partial`）、「聆听中…」**不得**触发展开；未截断的短回复无需点击。
- 调整底部输入区 Stack 层序或手势，确保字幕点击不被全屏按住 `Listener` 吞掉，且不影响按住说话 / 滑出取消。
- 不改变 `sendCommand` 协议、字幕框 52px 预览高度及转写/回复覆盖规则（`home-input-shared-caption`）。

## Capabilities

### New Capabilities

- `home-caption-expand-reply`：服务端回复字幕点击展开（BottomSheet）、截断检测与手势层隔离。

### Modified Capabilities

- `home-input-shared-caption`（delta）：补充服务端长回复可展开阅读的交互要求（预览仍固定 3 行）。

## Impact

- `app/lib/ui/home_input_caption.dart`（或可拆 `home_reply_bottom_sheet.dart`）
- `app/lib/ui/home_screen.dart`（Stack 层序、传入「是否为回复」与 `onExpandReply`）
- OpenSpec delta：`openspec/changes/home-input-shared-caption` 归档时合并（若存在基线）

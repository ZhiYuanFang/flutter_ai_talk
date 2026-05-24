## Why

主页底部主输入区高度固定（约 220px），实时转写预览（`_partial`）与服务端对话回复（`_chatReply`）原先上下叠放，回复出现后会把预览挤出可视区域，用户误以为云端无实时转写。需要将两类文案合并为**单一、固定高度**的展示位，并以**覆盖**方式切换内容。

## What Changes

- 语音模式：在语音球**上方**增加固定高度的「字幕框」；实时转写与服务端回复**共用**该框，同一时刻只显示一种文案（后者覆盖前者）。
- 松手后**保留**最后一帧转写预览，直至 `sendCommand` 返回的回复写入字幕框（覆盖转写）；新一轮按住说话时清空并重新显示转写。
- 文字模式：提交后同样在输入控件上方使用**同一套**字幕框展示服务端回复（与语音模式组件/逻辑复用），不再在输入区下方单独占一行回复。
- 不改变历史区、识别引擎、WS 协议及 `sendCommand` 载荷语义。

## Capabilities

### New Capabilities

- `home-input-shared-caption`：主页主输入区统一字幕框、转写/回复覆盖规则及语音/文字模式一致性。

### Modified Capabilities

- `home-input-history-sse`：补充主输入区须预留固定字幕区域、不得因回复叠层挤占转写可视性的要求（与历史区规范并列，不改动历史排序/渐隐规则）。

## Impact

- `app/lib/ui/home_screen.dart`（`_partial`、`_chatReply` 展示与生命周期）
- 可抽取 `app/lib/ui/home_input_caption.dart`（或等价小组件）供语音球与文字输入共用
- OpenSpec：`openspec/changes/pangbao-app/specs/home-input-history-sse` 的 delta 引用（归档时合并）

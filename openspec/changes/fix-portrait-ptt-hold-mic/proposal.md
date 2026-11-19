## Why

竖屏「去记录」长按 PTT 已能进入「请说话…」，但按住说话无实时 ASR、松手后像没说话；横屏语音正常。根因是服务端 `interrupt_commit` / 早到的 `asr_no_result` 在 `VoiceChatWsClient` 无条件停麦，而编排层只「忽略业务收口」、未保住上行，导致 UI 仍显示聆听、实际上行已空。

## What Changes

- 竖屏 PTT **按住期间**：收到服务端 `interrupt_commit` 或早到的 `asr_no_result` 时 MUST NOT 停麦；麦仅在松手 commit / 滑出取消 / 表面 teardown 时停止。
- 编排层与 WS 客户端对齐：hold 忽略抢先收口时，客户端侧也不得 `_stopMicOnly`；必要时提供 hold 门闩或回调。
- 按住期间若麦已异常停掉：pill/字幕 MUST NOT 继续伪装「请说话…」，须提示或自动续听。
- 补齐 hold 路径早退与抢先收口的 `[LandscapeVoice]` 日志，便于真机对照。
- （可选加固）PTT 开麦成功后再播 ding，或暂缓 ding，减少与录音焦点争用；不以该点为唯一修复。

## Capabilities

### New Capabilities

- （无）本变更为既有竖屏 PTT 行为修补。

### Modified Capabilities

- `prediction-fab-hold-voice`：明确按住期间服务端抢先 commit / 空结果不得停麦；松手仍为唯一业务 commit。
- `voice-chat-ws`：`interrupt_commit` / `asr_no_result` 在客户端 hold 门闩开启时 MUST NOT 自动停麦。

## Impact

- App：`VoiceChatWsClient`（`interrupt_commit` / `asr_no_result` 停麦策略）、`LandscapeVoiceController`（hold 门闩、事件处理、失败文案）、`PredictionGoRecordFab`（聆听态与真实开麦一致）。
- Go：无协议变更；服务端仍可下发 interrupt_commit，竖屏客户端按住时忽略其停麦副作用。
- 横屏：保持现有「吃 interrupt_commit 收口」行为，MUST NOT 回归。

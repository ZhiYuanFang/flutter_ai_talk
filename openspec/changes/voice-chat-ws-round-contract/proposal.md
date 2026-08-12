## Why

横屏 `/voice/chat/ws` 在首轮答完后常卡在「请说话…」：说话无反应、话筒点击也无效。根因是服务端成功 commit 后进入 `waitEndAfterCommit`，丢弃后续 PCM，直到客户端发送 `end` 再 `start`；同时是否续聊由服务端 `finish_talk` / `exit` 控制，而 App 既不发轮次 `end`/`start`，也不解析 `finish_talk`，与契约错位。需立刻对齐，否则多轮与假死无法消除。

## What Changes

- `VoiceChatWsClient`：解析 `answer` / `audio_end`（及等价结束帧）上的 `finish_talk`；在需要开启下一音频窗口前发送 `end` 再 `start`，清除服务端 `waitEndAfterCommit`。
- 横屏 `LandscapeVoiceController`：按服务端意图分支——`exit` 或 `finish_talk=true` 回唤醒；`finish_talk=false` 则同连接 `end`→`start`→`beginListen` 续听，不强制回 KWS。
- 解除「请说话」态下 `_turnBusy` / 芯片点击僵死：开听武装后允许话筒强制复位或结束忙标记，避免假死不可恢复。
- **客户端主动结束本段**（含 5s 无声 idle 退下「我先退下了」、`finish_talk=true` / `exit` 回唤醒）时 MUST 向服务端发送 `type=end`，不得只停麦回 KWS。
- 续听（`finish_talk=false`）重新开听时 MUST 重置有效音标志并重新武装既有 5s idle（阈值与退下 UX 仍由并行 idle change 定义）。
- 文档化双层契约：意图层（`exit`/`finish_talk`）与传输层（`waitEndAfterCommit` + `end`/`start`）。
- **不**改 Go 服务端门闩语义（本变更以客户端对齐现网契约为主）；G1 / 思考分段等并行 change 不在范围。

## Capabilities

### New Capabilities

- `voice-chat-ws-round-lifecycle`：`/voice/chat/ws` 话轮边界——解析 `finish_talk`、成功答完后的 `end`→`start`、客户端主动结束本段（含 idle 退下）MUST `end`、与 `exit` 的配合。
- `landscape-voice-multi-turn`：预测横屏按 `finish_talk` 续听或回唤醒、续听重武装 idle、idle 退下发 `end`、以及聆听假死时的芯片/忙标记恢复。

### Modified Capabilities

- （无）合并基线 `v2.1.0` 尚未收录 `voice-chat-ws` / 横屏语音细则；本变更以新 capability 约束行为。实现时复用进行中的 `prediction-landscape-voice-assistant`（`voice-chat-ws`）与并行 listen UX changes 的边界，不撤销其 PCM/指示灯/空结果/idle 语义。

## Impact

- 代码：`app/lib/voice/voice_chat_ws_client.dart`、`app/lib/providers/landscape_voice_provider.dart`；必要时 `app/README.md` 语音 WS 说明。
- 契约：对齐兄弟仓 `go_ai_talk` `voice_ws` 的 `waitEndAfterCommit`、`finish_talk`、`exit`（只读契约，本仓不改 Go）。
- 用户可见：多轮续聊不再假死；服务端要求结束或 5s 无声时回「说你好胖宝」且服务端会话被 `end` 清干净；芯片在卡死时可恢复。
- 日志：沿用既有 `AppDebugLog.landscapeVoice`，不新增裸 `print`。

## Why

预测横屏对话在思考与 TTS 期间会 `pause` 唤醒引擎，用户再说「你好，胖宝」无法打断；只能等话轮自然结束。投屏场景需要用同一唤醒词打断 AI 回合并立刻重开聆听。

## What Changes

- 在 **思考 + TTS** 窗口（服务端 `interrupt_commit` / 进入思考之后，至本段 `finishTurn` 之前）**提前恢复**本地 KWS，使唤醒词可再次命中。
- 打断手段 **仅** 再说「你好，胖宝」（或等价已配置唤醒词）；不以 chip / 任意人声作为本变更主路径。
- 命中后：立即停 TTS 与缓冲 → `endSession` 清服务端本轮 → 再走既有唤醒链（本地「我在」→ `beginListen`）。
- 「我在」本地播报与唤醒交接期间保持忙锁，避免自唤醒死循环；兼顾 TTS 回声误触的基本防护（阈值/短冷却，实现见 design）。
- 不改变待唤醒、用户上行聆听的既有主路径；不要求后台常听。

## Capabilities

### New Capabilities

- `landscape-voice-wake-barge-in`：预测横屏在思考/TTS 阶段支持唤醒词打断并重开对话。

### Modified Capabilities

- （无）基线未收录 barge-in；与 `voice-chat-ws-round-contract` / 多轮 `finish_talk` 并行兼容（打断后仍走 end→新一轮开听）。

## Impact

- 代码：`landscape_voice_provider.dart`、`voice_chat_ws_client.dart`（停 TTS API）、可能 `landscape_wake_word.dart`（resume 时机）。
- 服务端：优先复用既有 `end`；不强制新 cancel API（若后续 LLM cancel 另议）。
- 测试：不新建 `**/test/**`；真机思考中/播报中喊唤醒词验收。

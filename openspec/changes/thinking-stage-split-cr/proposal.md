## Why

流式 `thinking` / `thinking_delta` 当前在客户端做无脑拼接，服务端用 `\r` 划分的阶段性思考会堆成超长文案，横屏弹幕与陪伴聊天体验差。需要按 `\r` 做阶段切换：清空再写，让用户感知「分步思考」而非长文累计。

## What Changes

- 新增共享工具：对思考增量按 **`\r`** 分段（遇 `\r` 清空当前展示缓冲再续写；单独 `\n` 不清屏；若出现 `\r\n` 则清屏后跳过紧跟的 `\n`）。
- **横屏语音**：`landscape_voice_provider` 处理 `VoiceChatThinkingDelta` 时走该工具，更新 `thinking` 与弹幕。
- **陪伴聊天**：`pangbao_ai_screen` 处理 `thinking_delta` 时走同一工具。
- **不做**：首页 Tip 流、首页语音/指令条、死代码删除、Go 服务端改动、答语/TTS 弹幕规则变更。

## Capabilities

### New Capabilities

- `thinking-stage-split`：流式思考增量以 `\r` 为阶段分隔的客户端展示语义（横屏语音 + 陪伴）。

### Modified Capabilities

- （无）v2.1.0 基线未单独收录该展示规则；本变更以新增 capability 描述。

## Impact

- 新增：如 `app/lib/util/thinking_stage_delta.dart`（或等价路径）`applyThinkingStageDelta`。
- 修改：`app/lib/providers/landscape_voice_provider.dart`、`app/lib/ui/pangbao_ai_screen.dart`。
- 不改：`tip_provider`、`home_screen` 语音/指令、clinic 传输层本身（仅消费侧展示）。

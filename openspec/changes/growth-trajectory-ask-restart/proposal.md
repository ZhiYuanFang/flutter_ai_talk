## Why

成长轨迹在问答中途选错了，用户想整轮重来，但「重新预测」只在已有结果时出现。提问阶段按钮被藏掉，协议里的 `restart` 用不上。

## What Changes

- **提问阶段**展示「重新预测」，点击走已有 `restart`（空 `sessionId`，新会话从头问）。不是回到上一题改一个选项。
- **思考流进行中**仍不展示该按钮。此时请求还占着 Go 互斥，再开会被拒绝。
- 未完成的问答不计日限；重来后只有新结果落库才计一次。客户端不本地累计。日限已满时仍由服务端拒绝并 Toast。
- 重来失败时，若已有旧结果则回到该结果，不把页面清成空白。
- **不在本次范围**：撤销单题、`MemorySaver` 释放、改 Go / Python。

## Capabilities

### New Capabilities

- 无。

### Modified Capabilities

- `growth-trajectory-predict`：提问阶段必须提供「重新预测」并整轮重开；思考流进行中不得提供。

## Impact

- **Flutter**：`growth_trajectory_screen.dart`（提问阶段放出已有 `_GrowthBodyCta`，`startPredict(restart: true)`）。Provider 的 `restart` 路径已存在，不改契约。
- **Go / Python**：不改。`action=restart` 与空 `sessionId` 已支持。
- **测试**：不新建 `**/test/**`。
- **基线**：`openspec/specs/v2.1.0.md` 未收录本能力；对照未归档 `growth-trajectory-predict` 的「重新预测仅在有结果时出现」与「点击后隐藏主按钮」。本变更只补提问阶段的入口，不改日限计次规则。

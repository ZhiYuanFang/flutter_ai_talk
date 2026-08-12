## ADDED Requirements

### Requirement: 流式思考增量 MUST 以 CR 划分阶段展示

When applying streaming thinking deltas for landscape voice chat or companion (clinic) chat UI, the client MUST treat U+000D CARRIAGE RETURN (`\r`) as a stage boundary: clear the currently displayed thinking buffer, then append subsequent characters of the same and following deltas. A lone U+000A LINE FEED (`\n`) MUST NOT clear the buffer. If `\r` is immediately followed by `\n`, the client MUST clear and MUST skip that following `\n`. 在横屏语音对话或陪伴（诊疗）聊天 UI 应用流式思考增量时，客户端 MUST 将回车符 `\r`（U+000D）视为阶段边界：清空当前展示的思考缓冲，再追加本增量及后续增量中的后续字符。单独的换行符 `\n`（U+000A）MUST NOT 触发清空。若 `\r` 后紧跟 `\n`，客户端 MUST 清空并 MUST 跳过该 `\n`。

#### Scenario: 遇 CR 清空再写

- **WHEN** 当前展示思考为「阶段一」，增量包含 `\r` 及之后的「阶段二」
- **THEN** 展示 MUST 变为仅含「阶段二」（或等价地以「阶段二」为当前缓冲）
- **AND** MUST NOT 继续拼接为「阶段一」+「阶段二」长文

#### Scenario: 单独 LF 不清屏

- **WHEN** 思考增量中出现单独 `\n` 且其前不是未配对的阶段 `\r` 清屏逻辑所跳过的字符
- **THEN** 客户端 MUST NOT 仅因该 `\n` 清空思考缓冲
- **AND** MAY 将 `\n` 作为普通字符保留在当前阶段文案中

#### Scenario: CR LF 跳过 LF

- **WHEN** 增量（或跨增量拼接处理）中出现 `\r\n`
- **THEN** 客户端 MUST 在 `\r` 处清空
- **AND** MUST NOT 把紧跟的 `\n` 写入新阶段缓冲开头

#### Scenario: 横屏与陪伴一致

- **WHEN** 横屏语音收到 `thinking_delta` 或陪伴页收到 `thinking_delta`
- **THEN** 两处 MUST 使用同一套 `\r` 阶段规则更新用户可见的思考文案

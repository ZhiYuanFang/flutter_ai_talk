## ADDED Requirements

### Requirement: Arguments display SHALL differ by surface for debate posts

Debate post comments (arguments) MUST use existing flat comment API and `@mention` wire format. Display rules: **square feed** — inline first 5 with expand for remainder; **profile timeline** — MUST NOT show argument list on debate cards; **detail** — show all arguments without folding per `ucg-interactions`.

辩论论点复用评论 API；广场内联可展开；个人列表隐藏；详情全量。

#### Scenario: 广场展开论点

- **WHEN** 辩论帖有 8 条评论且用户在广场点击「展开」

- **THEN** 卡片 SHALL 就地展示全部 8 条且 MUST NOT 跳转详情

#### Scenario: 个人时间线隐藏论点

- **WHEN** 用户在个人主页时间线浏览 debate 帖

- **THEN** 卡片 MUST NOT 渲染论点列表

## MODIFIED Requirements

### Requirement: Long-press comment SHALL prefill reply with @nickname wire format

On detail page and square inline composer, long-pressing a comment SHALL open the comment composer with wire text prefilled `@${authorNickname}#${authorWxId} ` (trailing space) when wxId is known, else `@${authorNickname} `. User MAY edit before send. Mention text SHALL be included in `POST /posts/{id}/comments` body for server mention parsing.

详情与广场内联输入均须支持长按评论预填 @ 回复。

#### Scenario: 长按他人评论回复

- **WHEN** 用户在详情页或广场内联区长按**他人**评论

- **THEN** App SHALL 弹出输入框且 wire 内容预填 `@昵称#wxId `（有 wxId 时）

#### Scenario: 长按本人评论删除

- **WHEN** 用户在详情页长按**本人**评论

- **THEN** App SHALL 在评论上方展示删除操作且 SHALL NOT 预填 @ 回复

### Requirement: Comment composer SHALL separate display layer from submit wire for @mentions

The comment composer and comment list display layer on square and detail SHALL show `@nickname` only (strip `#wxId` suffix). The submitted `POST /posts/{id}/comments` body SHALL retain `@nickname#wxId` wire tokens. `@mention` spans in the composer SHALL be visually highlighted. Backspace at the end of or inside a mention token SHALL delete the entire segment atomically.

展示层隐藏 wxId；提交层保留 wire；广场与详情行为一致。

#### Scenario: 展示层隐藏 wxId

- **WHEN** 用户在 Composer 或评论列表查看含 `@昵称#123` 的内容

- **THEN** UI SHALL 仅渲染 `@昵称`

#### Scenario: 提交层保留 wxId

- **WHEN** 用户发送含 @ 回复的评论

- **THEN** POST body SHALL 含 `@昵称#wxId` 供服务端解析

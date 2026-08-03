## ADDED Requirements

### Requirement: Local button add success MUST start tip streaming

When a home button-path history add HTTP succeeds and yields a valid server record id, the client MUST call tip generation streaming (`tipProvider.startStreaming` or equivalent) with that event’s `deviceNo`, `eventId`, and `eventName`, and MUST NOT require History WebSocket readiness for this call. 本机按钮路径 add **成功**且取得有效服务端 id 后，客户端 **必须** 发起小贴士 SSE 流式生成，**不得**以 History WS 未就绪为由跳过。服务端 tip 限流（如 1h）导致无内容时客户端 MAY 保持面板 idle，属服务端策略，不在本需求强制展示。

#### Scenario: 本机添加成功触发 tip

- **WHEN** 用户经按钮路径成功添加一条喂养事件且 HTTP 返回有效 `data.id`
- **THEN** 客户端 MUST 调用 tip `startStreaming`（或等价）一次
- **AND** MUST NOT 因 `isHistoryWebSocketReady == false` 而跳过

#### Scenario: 添加失败不触发 tip

- **WHEN** add HTTP 失败（业务或传输）
- **THEN** 客户端 MUST NOT 发起 tip 流式请求

### Requirement: Tip panel done state MUST render Markdown headings

When tip `displayState` is `done` and the display text contains CommonMark-style ATX headings (e.g. lines beginning with `## `), the home tip panel MUST render them as headings via the same Markdown body widget used by smart companion answers (`ClinicAnswerBody` or equivalent), and MUST NOT show the raw `##` prefix as plain undecorated body text solely due to client rendering. tip 处于 `done` 且文案含 `##` 等 ATX 标题时，首页小贴士面板 **必须** 按陪伴同源 Markdown 组件渲染标题样式，**不得**因客户端渲染缺陷将 `##` 仅以纯文本字面展示。

#### Scenario: done 态 ## 标题

- **WHEN** tip 已 `done` 且 answer（或展示文本）含独立行 `## 标题`
- **THEN** 面板 MUST 以标题样式展示该行（非字面量 `## 标题` 纯文本）

#### Scenario: streaming 态可为纯文本

- **WHEN** tip 仍为 `streaming`
- **THEN** 客户端 MAY 以纯文本展示增量（与陪伴流式策略一致）

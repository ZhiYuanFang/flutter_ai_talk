## MODIFIED Requirements

### Requirement: Tier wall bodies SHALL render Markdown without algorithm jargon on Free

The Free tier body MUST be client-authored structured capability rows (or Markdown equivalent) that lists product capabilities with a leading emoji（or equivalent glyph）on each item, covering at least: next-time estimate from feeding frequency, smart push reminders, home-widget prediction, household sharing, landscape cast sharing on the prediction page, **long-press voice record via the go-record pill** (MUST NOT advertise a portrait wake voice-ball as the entry), multi-day baby trend charts, and Xiaozhi speaker connection with copy that the speaker connection capability can be paid to unlock. Free copy MUST NOT include a「能做什么」-style heading, MUST NOT show unordered-list `·` markers（emoji serves as the row label）, and MUST NOT mention algorithm internals or keywords such as「亲和」. The Pro tier body MUST render the catalog item `description` as Markdown when non-empty（fallback short plain copy when empty）. Body text MUST be left-aligned in a scroll view（MUST NOT force centered paragraph layout that breaks lists）. Tier hero images MUST use a compact fixed-height contain frame（MUST NOT use a full-width large 16:10 hero）. Non-actionable footers MUST use a light gray background and black/onSurface text.

免费档 MUST 为带行首 emoji 的能力清单；MUST 涵盖智能估算下次、推送提醒、桌面小组件、家庭共享、横向投屏、**长按去记录语音**、多日趋势、小智音箱；MUST NOT 再宣传竖屏语音球唤醒为入口；MUST NOT 出现亲和等算法词。

#### Scenario: Free 含约定能力且行首有图标

- **WHEN** 用户查看免费档/基础版能力列表
- **THEN** 正文 MUST 每条能力行首含 emoji（或等价标签图标）
- **AND** MUST 涵盖智能估算下次、推送提醒、桌面小组件、家庭共享、横向投屏、长按语音记录、多日趋势、小智音箱可付费开通连接
- **AND** MUST NOT 将「语音球唤醒」作为该条能力的现行标题/入口承诺
- **AND** MUST NOT 展示「能做什么」类标题
- **AND** MUST NOT 出现「亲和」等算法关键字

#### Scenario: Pro 渲染 catalog MD

- **WHEN** `predict_capability_pro.description` 非空且含 Markdown 列表标记
- **THEN** 墙内 Pro 正文 MUST 按 Markdown 展示（非原样纯文本一行）

## ADDED Requirements

### Requirement: Basic long-press-record row MUST pulse the go-record FAB

When the user taps the basic-tier capability row for long-press voice record (formerly voice-ball wake), the client MUST dismiss the tier wall and MUST publish a go-record FAB heartbeat guidance request so the prediction portrait「去记录」pill heartbeats three times for attention only. The client MUST NOT request portrait EdgeDock engage / showEngaged for that row. 点击基础版「长按语音记录」条目 MUST 关墙并请求「去记录」心跳 3 次；MUST NOT 再 engage 竖屏语音球。

#### Scenario: Tap guides to FAB heartbeat

- **WHEN** 用户在基础版墙点击长按语音记录条目
- **THEN** 墙 MUST 关闭
- **AND**「去记录」pill MUST 收到心跳指引并播放 3 次
- **AND** 客户端 MUST NOT 调用竖屏语音球 `showEngaged`（或等价）

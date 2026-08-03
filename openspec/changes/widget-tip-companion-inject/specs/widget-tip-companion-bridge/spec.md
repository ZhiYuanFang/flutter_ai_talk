## ADDED Requirements

### Requirement: Widget tip inject on companion entry SHALL use local day cache

When the user enters the smart companion and eligibility checks pass (consented, logged in, deviceNo present), if the home tip is not injectable and a same-calendar-day widget tip full text (or trimmed fallback) exists that has not yet been marked injected for that day, the client MUST append one tip-source assistant bubble with that text, persist the local clinic session store, and mark the widget tip injected for the day. 用户进入智能陪伴且资格满足时，若首页 tip 不可注入，且存在当日未注入的小组件 tip 文案，客户端 **必须** 追加一条 tip 源助手气泡、持久化本机会话，并标记该日已注入。

#### Scenario: 进陪伴注入当日小组件 tip

- **WHEN** 用户进入陪伴且同意/登录/deviceNo 有效
- **AND** 首页 tip 不可注入（非 done、已消费或无文案）
- **AND** prefs 中当日有小组件 tip 文案且 `injected_day` 不等于今日
- **THEN** 列表 MUST 追加一条 `isTipSource` 助手气泡（文案优先全文）
- **AND** 本机会话 store MUST 持久化该 tip 轮次
- **AND** 当日 MUST 标记为已注入

#### Scenario: 已注入则不再注入

- **WHEN** 当日小组件 tip 已标记 `injected_day == today`
- **AND** 用户再次进入陪伴
- **THEN** 客户端 MUST NOT 因小组件 tip 再追加助手气泡

### Requirement: Home tip inject SHALL take priority over widget tip

On the same companion-entry action, if the home tip is injectable, the client MUST inject the home tip and MUST NOT inject the widget tip in that same action. 同一次进入陪伴动作中，若首页 tip 可注入，客户端 **必须** 注入首页 tip，且 **不得** 在同一次动作中再注入小组件 tip。

#### Scenario: 首页 tip 优先

- **WHEN** 首页 tip `canInjectToCompanion` 为真
- **AND** 当日亦有未注入小组件 tip
- **AND** 用户进入陪伴
- **THEN** 客户端 MUST 仅注入首页 tip
- **AND** 小组件 tip 的 `injected_day` MUST NOT 因本次动作被标记

### Requirement: Widget tip inject SHALL occupy daily greeting

When a widget tip is injected on companion entry, the client MUST mark the daily companion greeting as completed for that calendar day and MUST NOT send the automatic「我来啦」message in that same entry action. 小组件 tip 在进入陪伴时注入成功后，客户端 **必须** 标记当日问候已完成，且同一次进入 **不得** 再自动发送「我来啦」。

#### Scenario: 注入后跳过我来啦

- **WHEN** 本次进入因小组件 tip 完成注入
- **THEN** `CompanionGreetingStore`（或等价）MUST 标记今日已问候
- **AND** 客户端 MUST NOT 在本次动作中发送「我来啦」

### Requirement: Widget tip fetch API SHALL remain history chat sync

The desktop widget tip content fetch MUST continue to use the synchronous `POST /device/history/api/chat` path via `fetchWidgetFeedingTip` (or equivalent), and MUST NOT switch to `/device/tip/generate` solely for this change. 桌面小组件 tip 拉取 **必须** 继续使用同步 `POST /device/history/api/chat`（经 `fetchWidgetFeedingTip` 或等价），本变更 **不得** 仅因此改为 `/device/tip/generate`。

#### Scenario: 拉取接口不变

- **WHEN** 客户端为小组件刷新 tip 文案
- **THEN** 请求 MUST 走 history chat 同步接口
- **AND** MUST NOT 因此调用 tip generate SSE

### Requirement: Widget sync MUST NOT write companion session store for tip inject

Successful home-widget sync or tip cache refresh MUST NOT append widget tip turns directly into `PangbaoClinicSessionStore` as the injection path; injection MUST occur on companion entry as specified above. 小组件同步或 tip 缓存刷新成功时 **不得** 以直接追加会话 store 作为注入路径；注入 **必须** 在进入陪伴时按上文要求发生。

#### Scenario: sync 不写陪伴 store

- **WHEN** `syncHomeWidgetFromRef`（或等价）成功刷新并推送小组件 tip
- **THEN** 客户端 MUST NOT 仅因此向陪伴会话 store 追加 tip 轮次

### Requirement: Clearing companion history MUST NOT reset widget tip injected day

Clearing the local companion chat history MUST NOT clear the widget tip `injected_day` mark for the current calendar day. 清理本机陪伴聊天记录时 **不得** 清除当日小组件 tip 已注入标记。

#### Scenario: 清记录后同日不再自动注入

- **WHEN** 用户清理陪伴记录
- **AND** 当日小组件 tip 此前已注入
- **AND** 用户再次进入陪伴
- **THEN** 客户端 MUST NOT 因小组件 tip 再次自动追加该日文案

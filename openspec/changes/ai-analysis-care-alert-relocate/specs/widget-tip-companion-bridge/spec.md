## MODIFIED Requirements

### Requirement: Widget tip inject on companion entry SHALL use local day cache

When the user enters the smart companion and eligibility checks pass (consented, logged in, deviceNo present), if the home tip is not injectable and a same-calendar-day widget tip full text (or trimmed fallback) exists that has not yet been marked injected for that day, the client MUST append one tip-source assistant bubble with that text, persist the local clinic session store, and mark the widget tip injected for the day. After this change, home-widget sync MUST NOT refresh or persist new widget tip copy for display; therefore when no prior same-day tip cache exists, companion entry MUST NOT inject a widget-tip bubble and MUST NOT fetch tip or care-alert daily solely to satisfy this bridge. 用户进入智能陪伴且资格满足时，若首页 tip 不可注入且仍存在当日未注入的小组件 tip 缓存，客户端 **必须** 按原规则注入；本变更后小组件 sync **不得** 再刷新/持久化新的展示用 tip，故无当日 tip 缓存时 **不得** 注入，且 **不得** 仅为桥接去拉 tip 或 care-alert daily。

#### Scenario: 无 tip 缓存则不注入

- **WHEN** 用户进入陪伴且同意/登录/deviceNo 有效
- **AND** 首页 tip 不可注入
- **AND** prefs 中无可用的当日小组件 tip 文案
- **THEN** 客户端 MUST NOT 因小组件 tip 追加助手气泡
- **AND** MUST NOT 仅为注入去请求 tip chat 或 care-alert daily

#### Scenario: 遗留当日缓存仍可注入一次

- **WHEN** 升级前 prefs 仍留有当日未注入的小组件 tip 文案
- **AND** 用户进入陪伴且首页 tip 不可注入
- **THEN** 客户端 MAY 按原桥接规则注入一次并标记已注入

### Requirement: Widget tip fetch API SHALL remain history chat sync

The desktop widget tip content fetch MUST continue to use the synchronous `POST /device/history/api/chat` path via `fetchWidgetFeedingTip` (or equivalent) **only if** a product path still explicitly requests tip text. This change MUST NOT use tip fetch or care-alert daily as part of routine home-widget sync for on-widget tip display. 若仍有产品路径显式需要 tip 文案，拉取 **必须** 继续走 history chat 同步接口；本变更下例行小组件 sync **不得** 为桌面 tip 展示去拉 tip 或 care-alert daily。

#### Scenario: 例行 sync 不拉 tip

- **WHEN** 客户端执行例行 `syncHomeWidgetFromRef`（或等价）以更新预测/recent
- **THEN** MUST NOT 调用 `fetchWidgetFeedingTip`（或等价）仅为填充桌面 tip
- **AND** MUST NOT 调用 care-alert daily 仅为派生 tip

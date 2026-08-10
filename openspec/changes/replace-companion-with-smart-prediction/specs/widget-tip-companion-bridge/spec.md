## REMOVED Requirements

### Requirement: Home tip inject SHALL take priority over widget tip
**Reason**: 首页 tip SSE / `HomeTipPanel` 已退役，不再存在「首页 tip 可注入」路径。
**Migration**: 进陪伴后仅按小组件 tip（full）注入规则；App 内下一步本地预测见 `home-prediction-tip-bar`。

## ADDED Requirements

### Requirement: Widget tip fetch SHALL continue for home-widget and prediction-page cache

Desktop widget tip content MUST continue to be fetched via the existing synchronous history chat path (`fetchWidgetFeedingTip` / `POST /device/history/api/chat` or equivalent), writing the shared day cache used by the home widget and the smart prediction page tip card. The client MUST NOT replace this fetch with `/device/tip/generate` solely due to this change.

小组件 tip **必须** 继续经 history chat 同步接口拉取并写入供桌面与预测页顶卡共用的日缓存；**不得** 仅因此改为 tip generate SSE。

#### Scenario: 拉取接口不变

- **WHEN** 客户端刷新小组件 tip 文案
- **THEN** 请求 MUST 走 history chat 同步接口
- **AND** MUST NOT 调用 `/device/tip/generate`

### Requirement: Opening prediction or feeding alone MUST NOT inject tip

Opening the smart prediction page or remaining on the feeding page MUST NOT, by itself, append widget tip text into the companion session store. Injection MUST occur only as part of entering companion (via the prediction tip-card push path in this change).

仅打开预测页或停留喂养页 **不得** 副作用注入陪伴会话；注入 **必须** 仅在进入陪伴时发生（本变更经 tip 卡 push）。

#### Scenario: 进预测页不注入

- **WHEN** 用户进入智能预测页但未打开陪伴
- **THEN** 客户端 MUST NOT 仅因此向陪伴会话追加 tip 气泡

### Requirement: Companion entry via tip card SHALL inject full widget tip when eligible

When the user opens companion from the prediction-page tip card and eligibility checks pass (e.g. consent, login, deviceNo as in existing companion inject rules), if a same-day widget tip full text (falling back to trimmed text) exists and has not yet been marked injected for that day, the client MUST inject that text as tip-source companion context and mark the day injected. Injection MUST prefer `full` text over trimmed text when full is available.

经 tip 卡进入陪伴且资格满足时，若当日有未注入的 tip，客户端 **必须** 注入并标记已注入；有全文时 **必须** 优先使用 full。

#### Scenario: 注入优先 full

- **WHEN** 用户经预测页 tip 卡进入陪伴且可注入
- **AND** 当日 cache 同时有 full 与 trim
- **AND** 当日尚未标记已注入
- **THEN** 注入文案 MUST 使用 full
- **AND** 当日 MUST 标记为已注入

#### Scenario: 已注入不再注入

- **WHEN** 当日 tip 已标记 injected
- **AND** 用户再次经 tip 卡进入陪伴
- **THEN** 客户端 MUST NOT 因小组件 tip 再次自动追加该日文案

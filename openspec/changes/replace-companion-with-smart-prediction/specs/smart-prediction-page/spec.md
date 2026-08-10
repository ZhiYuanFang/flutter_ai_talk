## ADDED Requirements

### Requirement: Home pager page 0 SHALL host the smart prediction page

The Flutter `/home` PageView index 0 SHALL render the smart prediction page (not Clinic/companion chat). The prediction page MUST NOT be built or mounted until the user first navigates to index 0. Deep link `/pangbao` (or equivalent legacy companion entry) MUST request navigation to the prediction page.

App `/home` PageView index 0 **必须** 为智能预测页而非 Clinic/陪伴聊天；首次进入前 **不得** mount；`/pangbao` 等旧入口 **必须** 切到预测页。

#### Scenario: 右滑首次挂载预测页

- **WHEN** 用户从喂养页横滑首次进入 page 0
- **THEN** App SHALL 挂载智能预测页
- **AND** MUST NOT 挂载陪伴聊天 UI 或激活 Clinic WS 作为该页职责

#### Scenario: /pangbao 进入预测页

- **WHEN** 用户打开 `/pangbao` 深链（或等价）
- **THEN** 客户端 MUST 导航至 `/home` 并请求 PageView 显示预测页（index 0）

### Requirement: Smart prediction page SHALL use glassmorphism visual language

The smart prediction page UI SHALL use a glassmorphism (玻璃拟化) visual language and MUST NOT reuse companion soft-neumorphism chrome as its primary surface system.

智能预测页 UI **必须** 采用玻璃拟化，**不得** 以陪伴软拟态作为主表面体系。

#### Scenario: 首屏为玻璃风格

- **WHEN** 用户打开智能预测页
- **THEN** 主列表/卡片表面 MUST 呈现玻璃拟化样式（可复用仓库既有 glass overlay/panel 模式）

### Requirement: Prediction list SHALL sort by nextAt and show per-event next point and countdown

The page SHALL list events that participate in local prediction, sorted by predicted `nextAt` ascending (overdue first per `event-interval-prediction`). For each event with prediction enabled and a computable prediction, the row MUST show that event’s own next occurrence affordance and a live countdown (or overdue copy). The client MUST NOT limit “highlight next point” to a fixed top-three subset.

列表 **必须** 按 `nextAt` 升序；每条启用且可预测的事件 **必须** 展示自己的下一点与倒计时（或已超时文案），**不得** 仅高亮固定 Top3。

#### Scenario: 两条事件各自倒计时

- **WHEN** 事件 A、B 均推演开启且均可预测，A.nextAt 早于 B.nextAt
- **THEN** 列表 MUST 先展示 A 再展示 B
- **AND** A 与 B 行均 MUST 展示各自的下次时间点与倒计时（或已超时）

### Requirement: Per-event forecast toggle SHALL persist locally and default ON

Each listed event SHALL expose a forecast（推演）toggle defaulting to ON. When OFF, the client MUST exclude that `eventId` from `predictAllUpcoming` consumption for this page and the home prediction tip, MUST gray out the row, MUST NOT show predicted next time/countdown for that row, and MUST NOT render that event’s chart. Toggle state MUST persist locally across app restarts until changed.

每事件推演开关默认开；关闭后 **必须** 不参与预测消费、置灰、无下次/倒计时、无折线，且 **必须** 本地持久化。

#### Scenario: 关闭推演置灰

- **WHEN** 用户关闭事件 A 的推演开关
- **THEN** A 行 MUST 置灰
- **AND** MUST NOT 展示 A 的下次时间与倒计时
- **AND** MUST NOT 展示 A 的折线图
- **AND** 顶栏「最近下一步」MUST NOT 选用 A（在 A 仍关闭期间）

#### Scenario: 重启后保持关闭

- **WHEN** 用户关闭事件 A 推演后杀死并重启 App
- **THEN** A 的推演开关 MUST 仍为关闭

### Requirement: Each prediction row SHALL show the event logo

For each listed event, the row SHALL display that event’s logo via shared `EventLogo` (catalog branding) adjacent to the event name. When forecast is OFF, the logo MAY remain visible under the same grayed opacity as the row.

每事件行 **必须** 在名称旁展示 `EventLogo`；推演关闭时 logo MAY 随行置灰。

#### Scenario: 行内展示 logo

- **WHEN** 智能预测页列出事件 A
- **THEN** A 行 MUST 展示 A 的事件 logo（或缺省占位）

### Requirement: Seven-day chart SHALL show one TOD-near point per day as dashed line

For each event with forecast ON and a computable prediction, the page SHALL render a chart over calendar days in `[now-6d, now]` explaining the predicted `nextAt` time-of-day: for each day that has at least one local occurrence (`occurrenceInstant`), the client MUST plot **at most one** point—the occurrence whose time-of-day is closest to `nextAt`’s time-of-day (circular minute distance). Days with no occurrence MUST omit a point. One axis MUST be calendar day; the other MUST be time-of-day. Connecting segments MUST be drawn as a **dashed** line. The chart MUST NOT plot every raw occurrence in the window.

推演开启且可预测时，折线 **必须** 解释 `nextAt` 时刻：`[now-6d, now]` 内每天至多一点（最接近 `nextAt` 时刻的 occurrence），无记录的天不画点；连接 **必须** 为虚线；**不得** 把窗口内全部发生点都画上。

#### Scenario: 每天至多一点

- **WHEN** 事件 A 在同一自然日有多次 occurrence，且存在 `nextAt`
- **THEN** 该日 MUST 仅贡献一个点（TOD 距 `nextAt` 时刻最近者）

#### Scenario: 虚线连接

- **WHEN** 至少有两个每日代表点
- **THEN** 连接折线 MUST 为虚线样式

#### Scenario: 关闭无折线

- **WHEN** 事件 A 推演关闭
- **THEN** UI MUST NOT 展示 A 的折线图

### Requirement: Entering prediction page SHALL prefetch seven-day history with chart loading

When the user first navigates to the smart prediction page in a session (or when history does not yet span 7 local days), the client MUST background-load additional history pages until `homeHistory` spans at least 7 days, or `hasMore` is false, or a timeout/circuit-break applies—using single-flight deduplication shared with or equivalent to widget history depth loading. While this prefetch is in flight, each forecast-enabled row’s chart area MUST show a loading affordance（「正在加载中」or equivalent）instead of treating sparse in-memory history as final empty charts.

进入预测页时，若历史未跨满 7 天，客户端 **必须** 后台分页拉取直至跨满 7 天或无更多/超时/熔断（single-flight）；拉取期间各推演开启行的图区 **必须** 展示加载中。

#### Scenario: 拉取中图区 loading

- **WHEN** 用户进入预测页且 7 日深度预拉尚未完成
- **THEN** 推演开启事件的折线区域 MUST 显示加载中
- **AND** MUST NOT 以「近 7 日暂无记录点」作为该预拉完成前的最终态（若仅因未加载）

#### Scenario: 跨满 7 天后出图

- **WHEN** 预拉完成且某事件在窗口内有每日代表点
- **THEN** 该事件折线 MUST 按每日一点规则渲染

### Requirement: Prediction page SHALL use existing event_next_predictor without new shared extract layer

Predicted `nextAt` / ranking MUST be computed via existing `predictAllUpcoming` / `predictNextForEventKey` (or equivalent wrappers) in `event_next_predictor.dart`. This change MUST NOT introduce an additional shared “prediction toolkit” abstraction layer beyond that module for algorithm reuse.

`nextAt`/排序 **必须** 经既有 `event_next_predictor`；本变更 **不得** 为复用算法再抽一层公共工具包。

#### Scenario: 与小组件同源算法

- **WHEN** 相同 history、catalog、birthDate、now 且无额外过滤
- **THEN** 预测页排序所用 `nextAt` MUST 与 `predictAllUpcoming` 结果一致（再叠加推演开关与 skip 过滤）

### Requirement: Prediction page SHALL show widget tip card when same-day tip cache exists

The smart prediction page SHALL show a top tip text card when a same-calendar-day desktop-widget tip cache entry exists (shared with home-widget tip cache, e.g. trimmed text). When no same-day tip cache text is available, the client MUST hide the entire tip card (no empty placeholder). The card MAY display the trimmed tip text used by the widget.

预测页顶部 **必须** 在存在当日小组件 tip cache 时展示文案卡；无当日 cache **必须** 隐藏整卡（不得空占位）。卡面文案 MAY 使用与桌面一致的 trim 文本。

#### Scenario: 有 cache 展示卡

- **WHEN** 当日 widget tip cache 存在非空文案
- **AND** 用户打开智能预测页
- **THEN** 页顶 MUST 展示 tip 文案卡

#### Scenario: 无 cache 隐藏卡

- **WHEN** 当日无可用 widget tip cache 文案
- **AND** 用户打开智能预测页
- **THEN** UI MUST NOT 渲染 tip 文案卡（无「暂无小贴士」占位）

### Requirement: Tip card tap SHALL push companion as the sole product entry

Tapping the prediction-page widget tip card MUST open companion chat via push navigation (e.g. full-screen route / `PangbaoAiScreen`), and MUST NOT mount companion as PageView index 0. For this change, that tip-card path MUST be the only user-visible product entry into companion (settings/other entries MUST remain closed or absent). Companion implementation sources MUST be retained.

点击 tip 卡 **必须** push 进入陪伴（不得再挂 PageView page 0）。本变更中该路径 **必须** 为唯一用户可见陪伴入口；陪伴源码 **必须** 保留。

#### Scenario: 点卡 push 陪伴

- **WHEN** 预测页展示 tip 文案卡
- **AND** 用户点击该卡
- **THEN** 客户端 MUST push 打开陪伴界面
- **AND** PageView index 0 MUST 仍为智能预测页（返回后可见）

#### Scenario: 无其它陪伴入口

- **WHEN** 审查本变更产品路径
- **THEN** 用户 MUST NOT 能从设置中心或其它本阶段入口进入陪伴（唯一入口为 tip 卡）

#### Scenario: 陪伴源码保留

- **WHEN** 完成本变更的代码审查
- **THEN** 陪伴主界面与 Clinic 客户端相关源文件 MUST 仍存在于工程中

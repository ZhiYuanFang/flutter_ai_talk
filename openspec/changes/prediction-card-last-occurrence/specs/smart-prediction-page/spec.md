## ADDED Requirements

### Requirement: Prediction event cards SHALL show last occurrence left-aligned on hot state

On the smart prediction page, for each rendered prediction event card in hot state (logged-in, bound, not demo skeleton), the client MUST show a left-aligned caption line formatted as `上一次{eventName}：{time}` where `{time}` uses the same local calendar rules as `formatWidgetLastAt` (today `HH:mm`, yesterday `昨天 HH:mm`, else `M月D日`). `{eventName}` MUST match the card title name shown for that row. The last occurrence instant MUST be derived from the root event’s merged history using the same `occurrenceInstant` semantics as prediction (`includeActive: true` for storage on the row). Cards MUST NOT show this line when the card is in active-timing chrome (`activeTiming != null`) or when the card is demo skeleton (`onToggle == null` / equivalent cold demo). Forecast-disabled cards MUST still show the last-occurrence line. Both list layout and grid/waterfall compact layout MUST show the line left-aligned.

智能预测页热态事件卡片 **必须** 靠左展示「上一次{事件名}：{时间}」；数据 **必须** 与 `occurrenceInstant` 一致并写入行模型；进行中计时与冷态骨架 **不得** 展示；推演关闭 **必须** 仍展示；列表与网格 **必须** 均靠左。

#### Scenario: 热态有历史无 nextAt

- **WHEN** 用户已登录已绑定且某事件卡片有历史但 `prediction == null`
- **THEN** 该卡片 MUST 靠左展示「上一次{事件名}：{时间}」
- **AND** MUST NOT 仅展示空 countdown 区而无上次时刻

#### Scenario: 推演关闭仍展示

- **WHEN** 用户关闭某事件推演且该 root 仍有历史记录
- **THEN** 该卡片 MUST 仍展示「上一次{事件名}：{时间}」

#### Scenario: 进行中计时不展示

- **WHEN** 网格卡片处于 active timing chrome（进行中计时）
- **THEN** 该卡片 MUST NOT 展示「上一次」行
- **AND** MUST 仍展示进行中 elapsed 与停止控件

#### Scenario: 冷态骨架不展示

- **WHEN** 预测页处于 demo skeleton（未登录或未绑定）
- **THEN** 骨架卡片 MUST NOT 展示「上一次」行

#### Scenario: 列表与网格均靠左

- **WHEN** 用户在列表布局或网格/瀑布布局查看同一热态事件
- **THEN** 两种布局 MUST 均靠左展示相同的「上一次」文案

### Requirement: Prediction card caption row SHALL place relative time left and toggle hint right

On prediction event cards, the caption row below the title MUST place relative prediction time text (including grid overdue `超时 …` or list `已超时 · …` / upcoming phrases) on the leading (left) side and the forecast toggle hint (`开启/关闭{eventName}预测`) on the trailing (right) side using horizontal space-between alignment. The client MUST NOT keep both strings in a single right-aligned cluster.

预测卡片标题下 caption 行 **必须** 左放相对时间/超时文案、右放推演开关说明；**不得** 再将二者整段靠右堆叠。

#### Scenario: 网格 overdue 左右分布

- **WHEN** 紧凑卡片 overdue 且展示 grid relativeText「超时 X 分钟」
- **THEN** 「超时 X 分钟」MUST 靠左
- **AND** 「关闭{事件名}预测」MUST 靠右

#### Scenario: 列表 upcoming 左右分布

- **WHEN** 列表卡片有 upcoming relativeText
- **THEN** relativeText MUST 靠左
- **AND** toggle hint MUST 靠右

#### Scenario: 无 relativeText 时

- **WHEN** 卡片无 relativeText（例如网格未 overdue）
- **THEN** toggle hint MUST 仍靠右
- **AND** 「上一次」行 MUST 在下一行靠左展示（热态且非计时非骨架）

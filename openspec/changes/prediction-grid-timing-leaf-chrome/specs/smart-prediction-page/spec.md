## MODIFIED Requirements

### Requirement: Grid card SHALL show active-timing chrome instead of nextAt countdown

When the smart prediction page is in grid/waterfall（compact）layout and the event for a card has an active timing history record (`eventNumber == 0` and end unset per existing `isActiveTimingRecord` rules), the card MUST NOT show the `nextAt` countdown main area or the large logo above that countdown. The card SHALL show: the **leaf** event logo (resolved from the active timing record via catalog lookup such as `lookupEventForRecord`) to the left of the **leaf** event display name; elapsed active duration in the card body using the same formatting rules as feeding active timing (`MM:SS` under one hour, `HH:MM:SS` at one hour or more); a bottom Stop control that ends the timing session via the existing history update API without a confirmation dialog; and MUST keep the forecast（推演）toggle on the title row. Elapsed text color and Stop control emphasis color MUST use the leaf event brand accent when resolvable. While Stop is enabled (not in-flight), the Stop control MUST play a continuous heartbeat scale animation. While a stop request is in flight, the heartbeat animation MUST pause and the control MAY show a busy label. If the leaf definition cannot be resolved, the client MUST fall back to a non-empty name (record or root row name) and a safe logo/accent fallback without crashing. Elapsed display MUST refresh at least every second while visible. Vertical list（non-compact）cards are out of scope for this requirement.

智能预测页处于网格/瀑布流（compact）布局且该卡事件存在进行中计时历史时，卡片 **不得** 展示指向 `nextAt` 的倒计时主区及其上方大图；**必须** 在标题左侧展示由进行中历史解析出的**叶子**事件 logo，标题文案 **必须** 为该叶子展示名；卡身 **必须** 展示已计时长（格式与喂养进行中计时一致）；底部「停止」经既有历史更新接口结束计时、**不得** 二次确认；标题行 **必须** 仍保留推演开关。已计时长与停止强调色在可解析时 **必须** 使用叶子事件品牌色。停止可点时 **必须** 持续心跳缩放动画；停止请求进行中时 **必须** 暂停心跳并可显示忙碌态。叶子定义不可解析时 **必须** 回退为非空名称与安全 logo/色，不得崩溃。可见时已计时长 **必须** 至少每秒刷新。纵向列表（非 compact）卡不在本要求范围内。

#### Scenario: 计时中展示叶子身份

- **WHEN** 布局为网格且根事件卡下存在叶子事件的进行中计时，且目录可解析该叶子
- **THEN** 标题旁 logo MUST 为该叶子事件图
- **AND** 标题文案 MUST 为该叶子事件名
- **AND** 已计时长与停止控件强调色 MUST 使用该叶子品牌色（可解析时）

#### Scenario: 计时中网格卡布局

- **WHEN** 布局为网格且事件 A 存在进行中计时记录
- **THEN** 卡身 MUST 显示递增的已计时长（非 `nextAt` 倒计时）
- **AND** 底部 MUST 有「停止」控件
- **AND** 标题行 MUST 仍显示推演开关
- **AND** MUST NOT 展示 `nextAt` 倒计时主区或倒计时上方大图

#### Scenario: 停止按钮心跳

- **WHEN** 网格计时中卡片展示「停止」且未在停止请求中
- **THEN** 「停止」控件 MUST 持续播放心跳缩放动画

#### Scenario: 停止进行中暂停心跳

- **WHEN** 用户已点击「停止」且请求尚未结束
- **THEN** 心跳动画 MUST 暂停
- **AND** 控件 MUST 呈现忙碌态（如「…」）且不可再次触发

#### Scenario: 停止结束计时

- **WHEN** 用户在网格计时中卡片点击「停止」且更新成功
- **THEN** 该历史记录 MUST 变为已结束
- **AND** 该卡片 MUST 退出计时中 chrome（恢复适用的非计时网格展示）

#### Scenario: 列表态不变

- **WHEN** 布局为纵向列表且事件 A 存在进行中计时
- **THEN** 本 Requirement MUST NOT 要求列表卡改为网格计时中 chrome

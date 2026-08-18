## REMOVED Requirements

### Requirement: Prediction tip SHALL be a bottom fixed horizontal marquee without tip chrome labels

**Reason**: 产品去掉预测页底栏 tip 跑马灯 chrome。

**Migration**: 删除 `_BottomTipMarquee` 挂载；桌面小组件 tip 推送可继续，但不在预测页底栏展示。

### Requirement: Tip marquee SHALL stay static when text fits the viewport

**Reason**: 随底栏 tip 删除。

**Migration**: 无。

### Requirement: Tapping the bottom tip bar SHALL open companion chat

**Reason**: 随底栏 tip 删除。

**Migration**: 用户仍可从其它入口进入陪伴。

### Requirement: Care-alert strip SHALL always show with state-specific body copy

**Reason**: 改为仅有真实留意条目时展示；loading/空/失败态不再占位。

**Migration**: 见 ADDED「仅非空成功态展示值得留意卡片」。

## ADDED Requirements

### Requirement: Care-alert card SHALL render only when daily fetch succeeded with non-empty items

The smart prediction page MUST render the「值得留意」card if and only if the care-alert daily fetch has succeeded (ready, not failed, not loading) and the client-filtered item list is non-empty. Otherwise the care-alert card area MUST NOT be shown (`SizedBox.shrink` or equivalent), including loading, empty success ("宝宝成长得真棒！"), API failure (including former VIP upsell copy), and cold-demo healthy placeholder cards. The next-3-hours timeline MUST NOT require a non-empty care-alert list.

智能预测页 **仅当** 日拉取成功且过滤后列表非空时 **必须** 展示「值得留意」卡片；loading / 空成功 / 接口异常（含原开通会员文案）/ 冷态健康假卡 **必须** 整块不展示。「接下来3小时」**不得** 要求留意非空。

#### Scenario: 有条目才展示

- **WHEN** 日拉取成功且过滤后至少一项
- **THEN** 页面 MUST 显示值得留意跑马灯卡片

#### Scenario: 空或失败不展示

- **WHEN** 日拉取失败，或成功但过滤后为空，或仍在 loading
- **THEN** 页面 MUST NOT 渲染值得留意卡片占位

#### Scenario: 空留意仍可显示三小时时间线

- **WHEN** 留意过滤后为空或不展示留意卡，且存在推演开启且 nextAt 在 now+3h 内的预测
- **THEN** 页面 MUST 仍可显示「接下来3小时」时间线

### Requirement: Auth swipe guide card SHALL omit UCG copy while pause gate is active

While the UCG home pause gate is active, the auth-guest swipe guide card on the smart prediction page MUST remain visible for logged-out / unbound chrome, and MUST NOT instruct the user to swipe into the square/UCG. Copy MUST guide toward feeding (and may keep a generic “swipe elsewhere” headline).

UCG 暂停闸门开启时，Auth 冷态滑动引导大卡 **必须** 仍展示，**不得** 出现「进广场」类指引；文案 **必须** 导向喂养（可保留泛化滑动主句）。

#### Scenario: 大卡无广场文案

- **WHEN** 用户未登录或未绑定且打开预测页，且 UCG 暂停闸门开启
- **THEN** 页面 MUST 展示滑动引导大卡
- **AND** 文案 MUST NOT 包含「广场」或「左滑进广场」

### Requirement: Prediction page MUST NOT show a bottom tip marquee

The smart prediction page MUST NOT render a bottom-fixed tip bar or horizontal tip marquee, even when widget tip text is non-empty.

智能预测页 **即使** 有 tip 文案也 **必须 NOT** 渲染底部 tip 条/横向跑马灯。

#### Scenario: 有 tip 文案也不展示底栏

- **WHEN** `widgetTipCardTextProvider`（或等价）返回非空文案
- **THEN** 预测页 MUST NOT 渲染底部 tip 跑马灯

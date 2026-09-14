## ADDED Requirements

### Requirement: Logged-in client MUST silently report usage with featureId and description

The client SHALL call `POST /device/app/api/client-usage/report` with a valid Bearer session and JSON body containing non-empty trimmed `featureId` and `description`. Both fields MUST NOT contain `|`. The client MUST NOT show toast or other user-visible errors when the report fails (network, business error, or rate limit); failures MUST be discarded from the user perspective. Unauthenticated sessions MUST NOT invoke the report API.

客户端在已登录会话下必须上报 `featureId` 与运维可读的 `description`；失败必须静默丢弃、用户无感知；未登录不得调用。

#### Scenario: Successful silent report

- **WHEN** 用户已登录且业务触发一次合法上报
- **THEN** 客户端必须向 `POST /device/app/api/client-usage/report` 提交含非空 `featureId` 与 `description` 的 JSON，且不得因本次上报向用户展示错误提示

#### Scenario: Failure is user-invisible

- **WHEN** 上报因网络错误、业务错误或服务端限流失败
- **THEN** 客户端必须丢弃该次结果，不得 toast，不得阻断当前 UI 流程

#### Scenario: Guest does not report

- **WHEN** 用户未登录
- **THEN** 客户端不得调用 client-usage report 接口

### Requirement: Page show events MUST cover home pager, UCG surfaces, and all routed screens

The client SHALL emit a page-show usage report when each distinct product surface becomes visible, including: home shell PageView pages (feeding, prediction, UCG shell entry), UCG tabs (square/home, messages, profile), UCG compose screen when opened, and **all** GoRouter-reachable product screens that users can open after login (including settings and other non-pager routes). KeepAlive / IndexedStack pages MUST report on becoming the current visible page, not only on first `initState`. Cold start landing on prediction MUST still report prediction show even if `onPageChanged` does not fire.

客户端必须在独立产品页变为可见时上报展示事件，覆盖主壳 PageView、UCG 子表面与发布页、以及全部路由页（含设置）；KeepAlive 页须在再次可见时按可见切换上报；冷启落在预测页也必须补报。

#### Scenario: Home pager page show

- **WHEN** 用户滑入喂养页、预测页或 UCG 壳页（含冷启已停在预测页）
- **THEN** 客户端必须分别上报对应页的展示事件（含稳定 `featureId` 与中文 `description`）

#### Scenario: UCG tab and compose show

- **WHEN** 用户切换到 UCG 广场、消息或我的 Tab，或打开发布动态页
- **THEN** 客户端必须上报对应表面的展示事件

#### Scenario: Settings and other routed screens show

- **WHEN** 用户进入设置页或其它 GoRouter 产品页（如 AI 分析、开通中心、VIP、绑宝宝、趋势等）
- **THEN** 客户端必须上报该页展示事件，不得仅覆盖主壳 pager 页

### Requirement: Prediction card toggle MUST report on/off with list order and event type

When the user successfully toggles a prediction card forecast switch (non-demo), the client SHALL report `prediction_card_toggle_on` or `prediction_card_toggle_off` with a `description` that includes: (1) on/off wording, (2) **1-based index** equal to the card’s index in the current `rows` array plus one, and (3) the event’s display name (fallback to `eventId` if unnamed). Demo skeleton cards without a real toggle MUST NOT emit toggle reports.

用户切换真实预测卡片开关时，客户端必须上报 on/off，且 description 必须含列表数据序（rows 下标+1）与事件类型显示名；演示骨架不得上报开关事件。

#### Scenario: Enable forecast on first list row

- **WHEN** 用户开启 `rows` 中下标为 0 的卡片预测开关，且该行事件显示名为「喝奶」
- **THEN** 客户端必须上报 `featureId=prediction_card_toggle_on`，且 `description` 必须同时体现开启、顺序 1、以及「喝奶」（或等价显示名）

#### Scenario: Disable forecast preserves order and event

- **WHEN** 用户关闭 `rows` 中下标为 4 的卡片预测开关
- **THEN** 客户端必须上报 `featureId=prediction_card_toggle_off`，且 `description` 必须含顺序 5 与该行事件类型信息

### Requirement: Layout, theme, and baby-avatar actions MUST be reported

The client SHALL report when the user toggles prediction cards layout (list vs grid/waterfall) and when the user toggles UCG square feed layout. The client SHALL report when the theme palette entry is opened, and separately when a theme change is successfully applied (including clear-to-classic). The client SHALL report when a baby avatar change is successfully persisted locally. Failed avatar picks or cancelled theme sheets MUST NOT emit success events.

客户端必须上报：预测/UCG 列表形态切换、主题入口点击、主题切换成功、宝宝头像更换成功；取消或失败不得报成功事件。

#### Scenario: Layout toggle

- **WHEN** 用户在预测页或 UCG 广场成功切换列表/瀑布（或等价布局）
- **THEN** 客户端必须上报对应布局切换事件，description 须表明切换后的形态

#### Scenario: Theme open vs success

- **WHEN** 用户点击调色盘入口
- **THEN** 客户端必须上报主题入口事件
- **WHEN** 用户成功应用某一主题预设、自定义色或恢复经典
- **THEN** 客户端必须另报主题切换成功事件（与入口事件区分）

#### Scenario: Baby avatar success

- **WHEN** 用户成功将新宝宝头像落盘到本地存储
- **THEN** 客户端必须上报宝宝头像更换成功事件
- **WHEN** 用户取消选图或落盘失败
- **THEN** 客户端不得上报成功事件

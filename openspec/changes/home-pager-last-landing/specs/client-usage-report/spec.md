## MODIFIED Requirements

### Requirement: Page show events MUST cover home pager, UCG surfaces, and all routed screens

The client SHALL emit a page-show usage report when each distinct product surface becomes visible, including: home shell PageView pages (feeding, prediction, UCG shell entry), UCG tabs (square/home, messages, profile), UCG compose screen when opened, and **all** GoRouter-reachable product screens that users can open after login (including settings and other non-pager routes). KeepAlive / IndexedStack pages MUST report on becoming the current visible page, not only on first `initState`. Cold start landing on the home pager MUST still report the **actual** landing page’s show event (feeding or prediction per `home-pager-last-landing`) even if `onPageChanged` does not fire.

客户端必须在独立产品页变为可见时上报展示事件，覆盖主壳 PageView、UCG 子表面与发布页、以及全部路由页（含设置）；KeepAlive 页须在再次可见时按可见切换上报；冷启落在主壳哪一页就必须补报哪一页（喂养或预测）。

#### Scenario: Home pager page show

- **WHEN** 用户滑入喂养页、预测页或 UCG 壳页（含冷启已停在喂养或预测页）
- **THEN** 客户端必须分别上报对应页的展示事件（含稳定 `featureId` 与中文 `description`）

#### Scenario: Cold start lands on remembered feeding

- **WHEN** 冷启主壳因 lastPage 停在喂养且 `onPageChanged` 未因 initial 触发
- **THEN** 客户端 MUST 仍上报喂养页展示事件
- **AND** MUST NOT 仅因历史「默认预测」而误报预测展示

#### Scenario: Cold start lands on prediction

- **WHEN** 冷启主壳停在预测页且 `onPageChanged` 未因 initial 触发
- **THEN** 客户端 MUST 仍上报预测页展示事件

#### Scenario: UCG tab and compose show

- **WHEN** 用户切换到 UCG 广场、消息或我的 Tab，或打开发布动态页
- **THEN** 客户端必须上报对应表面的展示事件

#### Scenario: Settings and other routed screens show

- **WHEN** 用户进入设置页或其它 GoRouter 产品页（如 AI 分析、开通中心、VIP、绑宝宝、趋势等）
- **THEN** 客户端必须上报该页展示事件，不得仅覆盖主壳 pager 页

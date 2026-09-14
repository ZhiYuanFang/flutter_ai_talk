## MODIFIED Requirements

### Requirement: AI analysis page SHALL host feeding analysis and growth trajectory modules

The client SHALL provide a dedicated AI analysis **hub** route that contains exactly two primary **entry** cards stacked vertically: (1) feeding-record analysis and (2) growth-trajectory prediction. The hub MUST be reachable from the next-3-hours 「AI分析」 control. The hub MUST act as an entitlement gate and MUST NOT run the full feeding list/refresh workspace or the full growth Q&A/SSE workspace inline. Unlocked users MUST navigate to dedicated child routes to perform those AI capabilities. 客户端 **必须** 提供 AI 分析 Hub 路由，纵向两张能力入口卡；**必须** 可由「接下来3小时」上的「AI分析」进入；Hub **必须** 作为资格门且 **不得** 页内嵌完整喂养工作台或成长问答工作台；已开通用户 **必须** 进入子路由完成业务。

#### Scenario: 从预测页进入 Hub

- **WHEN** 用户在智能预测页点击「接下来3小时」卡片上的「AI分析」
- **THEN** 客户端 MUST 打开 AI 分析 Hub
- **AND** 页面 MUST 同时展示喂养记录分析入口卡与成长轨迹预测入口卡

#### Scenario: 已开通进入子页

- **WHEN** 用户对某能力已有效开通（含 VIP 合成）
- **AND** 用户点击该入口卡
- **THEN** 客户端 MUST 导航至对应子路由工作台
- **AND** MUST NOT 仅在 Hub 卡内完成该能力的列表刷新或 SSE 问答主流程

### Requirement: Feeding analysis module SHALL show eligibility and unlock gates

When the user is logged in and bound, the **hub** feeding card SHALL render care-alert feeding-day eligibility progress and unlock CTAs while gated. The hub MUST NOT call `care-alert/daily` solely because eligibility or catalog was ensured. Only after effective unlock MAY the user enter the feeding workspace route. 已登录绑定用户在 Hub 喂养卡上 **必须** 在未放行时展示资格进度与开通引导；仅 ensure 资格/目录时 **不得** 调用 daily；**仅** 有效开通后 MAY 进入喂养子页。

#### Scenario: 未合格展示进度

- **WHEN** cash care-alert eligibility 未合格且已返回数据
- **THEN** Hub 喂养卡 MUST 展示有效喂养日进度文案或等价进度控件
- **AND** MUST NOT 导航进入喂养工作台完成 daily 分析

#### Scenario: 合格未开通

- **WHEN** eligibility 已合格且功能未开通且非 VIP 覆盖
- **THEN** Hub 喂养卡 MUST 展示开通引导（邀请码等既有路径）
- **AND** MUST NOT 展示可进入工作台的已开通入口语义作为唯一动作

## ADDED Requirements

### Requirement: AI analysis hub unlocked cards SHALL show entitlement remaining time

When a hub capability card is effectively unlocked, the card SHALL display entitlement remaining-time copy using catalog `expiresAt` via `featureRemainingDaysCopy` when the feature grant is time-bounded; when unlock is VIP-synthesized without a feature-specific expiry, the card SHALL use VIP `expireAt` remaining copy; permanent grants MAY show 永久. 当 Hub 能力卡已有效开通时 **必须** 展示权益时效：功能限时用 catalog `expiresAt` 的「剩余 N 天」文案；VIP 合成开通用 VIP 到期剩余；永久开通 **可以** 展示「永久」。

#### Scenario: 限时功能开通

- **WHEN** 用户功能项 `unlocked` 且 `expiresAt > 0`
- **THEN** 对应 Hub 卡 MUST 展示剩余天数类时效文案

#### Scenario: VIP 合成开通

- **WHEN** 用户非功能单独开通但因 VIP 对该能力有效开通
- **AND** VIP 有到期时间
- **THEN** 对应 Hub 卡 MUST 展示基于 VIP 到期的剩余时效文案

### Requirement: Feeding once-per-day expectation copy SHALL appear on hub and workspace

The feeding hub card (when unlocked) and the feeding workspace screen SHALL both display compact helper copy stating that analysis is supported only once per day (文案：每日仅支持分析一次 or equivalent). This copy is informational and MUST NOT by itself hide the 「AI智能分析」 control. 喂养 Hub 已开通卡与喂养工作台 **必须** 展示「每日仅支持分析一次」（或等价）小字说明；该文案 **不得** 单独作为隐藏「AI智能分析」的条件。

#### Scenario: Hub 与子页均可见

- **WHEN** 用户已开通喂养分析并查看 Hub 喂养卡
- **THEN** 卡上 MUST 可见每日一次说明
- **WHEN** 用户进入喂养工作台
- **THEN** 工作台 MUST 再次可见每日一次说明

### Requirement: Feeding and growth workspaces SHALL live on child routes

The client SHALL provide a feeding analysis workspace route and a growth-trajectory workspace route reachable from the hub after unlock. The feeding workspace SHALL host list + manual 「AI智能分析」 and item navigation to the existing care-alert detail route. The growth workspace SHALL host unlock-gated prediction session UI conforming to `growth-trajectory-predict`. 客户端 **必须** 提供喂养与成长子路由工作台；喂养工作台 **必须** 承载列表与手动「AI智能分析」及进既有详情；成长工作台 **必须** 承载符合 `growth-trajectory-predict` 的预测会话 UI。

#### Scenario: 喂养子页职责

- **WHEN** 用户从 Hub 进入喂养工作台且已开通
- **THEN** 页面 MUST 可展示「AI智能分析」与列表（或空态）
- **AND** 点击列表项 MUST 打开既有 `/prediction/alert`（或等价）详情

#### Scenario: 成长子页职责

- **WHEN** 用户从 Hub 进入成长工作台且已开通
- **THEN** 页面 MUST 可进行轨迹预测 / 问答 / 结果展示
- **AND** Hub MUST NOT 为展示历史而在仅停留 Hub 时强制 `ensureLatest`

### Requirement: Growth trajectory module on AI analysis hub SHALL gate then defer to workspace

Behavior of unlock on the hub growth card SHALL remain consistent with `growth-trajectory-predict` unlock rules. SSE Q&A, thinking, daily-limit toasts, and result rendering SHALL run on the growth workspace route, not inline on the hub. Hub 成长卡开通规则 **必须** 符合 `growth-trajectory-predict`；SSE 问答、思考、日限 Toast 与结果渲染 **必须** 在成长子页进行，**不得** 在 Hub 内联主流程。

#### Scenario: 规格交叉引用

- **WHEN** 实现或验收 AI 分析成长路径
- **THEN** 验收 MUST 同时满足本页 Hub/子页 Requirement 与 `growth-trajectory-predict` 各 Requirement

## REMOVED Requirements

### Requirement: Manual care-alert refresh SHALL use AI智能分析 and 正在思考中

**Reason**: 喂养分析主流程迁至子页；客户端一日一刷藏钮废除，行为改由 `prediction-care-alert` 工作台规则约束。

**Migration**: 见同变更 `specs/prediction-care-alert/spec.md` 中「喂养工作台手动 AI智能分析」Requirement。

### Requirement: Feeding analysis list SHALL open existing care-alert detail

**Reason**: 列表改在喂养工作台展示。

**Migration**: 见同变更 `prediction-care-alert`「Feeding analysis list SHALL open existing care-alert detail from workspace」。

### Requirement: Growth trajectory module on AI analysis page SHALL follow growth-trajectory-predict capability

**Reason**: 成长主流程迁至子页；Hub 仅门闸，交叉引用改由「Growth trajectory module on AI analysis hub SHALL gate then defer to workspace」表达。

**Migration**: 见同文件 ADDED 的 Hub gate + workspace Requirement；会话行为仍验收 `growth-trajectory-predict`。

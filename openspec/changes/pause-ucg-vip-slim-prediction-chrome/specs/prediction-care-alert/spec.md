## REMOVED Requirements

### Requirement: Prediction care-alert fail strip SHALL branch by VIP status

**Reason**: 失败态整卡隐藏，不再展示「开通会员查看每日提醒」或 VIP 分流。

**Migration**: 失败时不渲染值得留意卡片；VIP 购买入口见 `vip-purchase-ux` 暂停闸门。

### Requirement: Returning from VIP purchase as VIP SHALL reload care-alert daily

**Reason**: 预测页不再提供开通回流路径。

**Migration**: 无。

### Requirement: Cold prediction states SHALL show fixed healthy care-alert copy without HTTP

**Reason**: 冷态健康假卡不再展示。

**Migration**: 冷态仍禁止 care-alert 日拉取（门闸可保留）；UI 不渲染假卡。

## ADDED Requirements

### Requirement: Care-alert UI SHALL hide unless successful non-empty list

The client MUST NOT show the prediction-page「值得留意」shell for loading, not-ready, failed, empty-success, VIP upsell, or cold-demo placeholder states. The shell MUST appear only when daily fetch succeeded and the filtered event item list is non-empty (marquee + detail navigation as before). Cold demo states MUST NOT render `_CareAlertDemoHealthyPanel` (or equivalent fixed healthy card).

客户端 **不得** 在 loading / 未就绪 / 失败 / 空成功 / 会员开通文案 / 冷态假卡状态下展示值得留意外壳；**仅当** 成功且非空时展示跑马灯。冷态 **不得** 渲染健康假卡。

#### Scenario: 冷态无假卡

- **WHEN** 智能预测页处于冷态骨架模式（已登录场景下的空历史冷态）
- **THEN** UI MUST NOT 展示值得留意健康假卡

#### Scenario: 失败无开通文案

- **WHEN** care-alert daily 失败且非 loading
- **THEN** 预测页 MUST NOT 展示「开通会员查看每日提醒」
- **AND** MUST NOT 展示「接口异常」留意卡片

#### Scenario: 非空仍可进详情

- **WHEN** 过滤后列表非空且用户点击某条留意
- **THEN** 客户端 MUST 仍可导航至留意详情（忽略/追问等既有能力保留）

### Requirement: Care-alert detail MUST NOT show VIP purchase CTA while pause gate is active

While the VIP purchase pause gate is active, the care-alert detail screen MUST NOT show a bottom「开通 VIP」CTA (or equivalent), regardless of VIP status.

VIP 购买暂停闸门开启时，留意详情 **必须 NOT** 展示底部开通 CTA。

#### Scenario: 详情无开通按钮

- **WHEN** 暂停闸门开启且用户打开留意详情
- **THEN** 页面 MUST NOT 展示「开通 VIP」底部按钮

## ADDED Requirements

### Requirement: Prediction care-alert fail strip SHALL branch by VIP status

When the smart prediction page「值得留意」daily fetch has failed and is not loading, the client MUST branch the strip by VIP status. When the user is not VIP (including VIP status unknown or status load failure treated as non-VIP), the strip MUST show the exact copy「开通会员查看每日提醒」, MUST NOT show the refresh control, and MUST navigate to the VIP purchase route on tap (on Web, MUST follow the existing App-only purchase guidance instead of native purchase). When `isVip` is true, the strip MUST keep「接口异常」with a refresh affordance that force-reloads the daily cache.

预测页「值得留意」日拉取失败且非 loading 时，客户端 **必须** 按 VIP 分流：非 VIP（含状态未知/失败按非 VIP）**必须** 展示「开通会员查看每日提醒」、**不得** 展示刷新，点击 **必须** 进入 VIP 购买路由（Web 遵循既有仅 App 开通引导）；已是 VIP 时 **必须** 保留「接口异常」+ 刷新强制重拉。

#### Scenario: 非 VIP 失败态开通文案

- **WHEN** care-alert daily 失败且非 loading，且当前账号非 VIP（或 VIP 状态未知）
- **THEN** 卡片 MUST 展示「开通会员查看每日提醒」，MUST NOT 展示刷新按钮

#### Scenario: 非 VIP 点击开通

- **WHEN** 用户在非 VIP 失败态点击该开通文案行（非 Web）
- **THEN** 客户端 MUST 导航至 `/vip/purchase`（或等价 VIP 购买路由）

#### Scenario: 已是 VIP 失败态

- **WHEN** care-alert daily 失败且非 loading，且 `isVip` 为 true
- **THEN** 卡片 MUST 展示「接口异常」并提供刷新；点击刷新 MUST `ensureLoaded(force: true)`（或等价强制重拉）

### Requirement: Returning from VIP purchase as VIP SHALL reload care-alert daily

After the user leaves the VIP purchase flow and returns to the prediction care-alert strip context, the client MUST refresh VIP status. When the refreshed status reports `isVip` true, the client MUST force-reload the care-alert daily cache. When the user is still not VIP, the client MUST NOT force-reload solely because of returning from purchase.

用户从 VIP 购买流程返回后，客户端 **必须** 刷新 VIP 状态；若已是 VIP，**必须** 强制重拉 care-alert 日缓存；若仍非 VIP，**不得** 仅因返回购买页而强制重拉。

#### Scenario: 开通成功后重拉

- **WHEN** 用户从 `/vip/purchase` 返回，且刷新后 `isVip` 为 true
- **THEN** 客户端 MUST 对 care-alert daily 执行强制重拉

#### Scenario: 未开通返回不重拉

- **WHEN** 用户从购买页返回，且刷新后仍非 VIP
- **THEN** 客户端 MUST NOT 仅因此触发 care-alert daily 强制重拉

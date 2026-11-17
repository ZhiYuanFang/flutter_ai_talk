## MODIFIED Requirements

### Requirement: Tier footers SHALL be non-button status labels this release

This release MUST NOT offer in-wall trial or payment CTAs for Pro. Footer chrome for non-actionable states MUST NOT look like a tappable button（MUST NOT use the filled/glass outlined button chrome with InkWell）. It MUST present as a status label with a **light gray** background and **black / onSurface** text（MUST NOT use tier accent for footer fill or label color）. Labels MUST be：基础版 slide always「正在使用」（including when the user already has Pro）；Pro when time-valid unlocked「正在使用」；otherwise Pro「敬请期待」. When the Pro footer shows「敬请期待」and catalog `predict_capability_pro.defaultProduct.priceFen` is greater than zero, the client MUST append a **smaller** same-line price hint after that label in the form `¥{amount}/月`, where `{amount}` is derived from that `priceFen`（fen→yuan）and the `/月` suffix is a **fixed** product copy（MUST NOT derive the period from `durationDays`）. When there is no default product or `priceFen` is not greater than zero, the client MUST omit the price hint and show only「敬请期待」. The「正在使用」footer MUST NOT show the price hint. Idea collection CTAs（「我有想法」/「我有更多想法」）MUST live **inside** the Pro card (or open a separate compose sheet) and MUST NOT replace these footer status labels. The client MUST NOT show「当前可用」on this wall. The 基础版 slide title MUST be「基础版」（MUST NOT「免费版」）. The client MUST NOT invent a local price when catalog has no usable `priceFen`.

本版墙内 MUST NOT 提供 Pro 试用/支付 CTA；卡外脚 MUST 保持浅灰底黑字「正在使用」/「敬请期待」状态标签；Pro「敬请期待」在有 catalog 价时 MUST 同行小字 `¥金额/月`（`/月` 写死），无价 MUST 隐藏小字；「正在使用」MUST NOT 挂价；想法入口 MUST 在卡内（或独立 Sheet），MUST NOT 替换卡外脚；MUST NOT「当前可用」；标题 MUST NOT「免费版」；MUST NOT 本地编价。

#### Scenario: 基础版脚恒正在使用

- **WHEN** 用户已开通 Pro 并滑到基础版档
- **THEN** 基础版档脚 MUST 显示「正在使用」且不可点、非按钮形态
- **AND** 该档标题 MUST 为「基础版」
- **AND** MUST NOT 在该脚展示价格小字

#### Scenario: Pro 未开通敬请期待带月价

- **WHEN** Pro 未开通且 catalog `predict_capability_pro.defaultProduct.priceFen` > 0
- **THEN** Pro 档脚 MUST 显示「敬请期待」且不可点、非按钮形态
- **AND** MUST 在「敬请期待」同一行后面以更小字号展示 `¥{由 priceFen 换算}/月`
- **AND** `/月` MUST 为固定文案，MUST NOT 由 `durationDays` 推导
- **AND** MUST NOT 因展示价格而提供可点支付/试用

#### Scenario: Pro 未开通无价隐藏小字

- **WHEN** Pro 未开通且无 defaultProduct 或 `priceFen` ≤ 0
- **THEN** Pro 档脚 MUST 仅显示「敬请期待」
- **AND** MUST NOT 展示价格小字或占位金额

#### Scenario: Pro 已开通正在使用

- **WHEN** `predict_capability_pro` 有效开通
- **THEN** Pro 档脚 MUST 显示「正在使用」且不可点、非按钮形态
- **AND** MUST NOT 在该脚展示价格小字

#### Scenario: Ideas CTA not footer

- **WHEN** 用户要提交想法
- **THEN** 入口 MUST 来自卡内「我有想法」或「我有更多想法」（打开 Sheet）
- **AND** MUST NOT 将卡外脚改为可点「提交意见」或支付开通

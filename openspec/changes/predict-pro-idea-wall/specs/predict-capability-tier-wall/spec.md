## ADDED Requirements

### Requirement: Pro tier SHALL keep catalog body and host ideas empty or list surfaces

On the Pro slide, the primary body MUST continue to render `predict_capability_pro.description` as Markdown when non-empty（existing short fallback when empty）. Below that body the client MUST host the predict-pro-ideas empty state or non-empty list per `predict-pro-idea-client`. The client MUST NOT splice idea texts into the catalog Markdown string. Pro 正文 **必须** 仍来自 catalog；想法区 **必须** 独立托管。

#### Scenario: Catalog body source

- **WHEN** catalog `description` 更新后用户打开 Pro 档
- **THEN** 主正文 MUST 反映服务端当前 description

## MODIFIED Requirements

### Requirement: Tier footers SHALL be non-button status labels this release

This release MUST NOT offer in-wall trial or payment CTAs for Pro. Footer chrome for non-actionable states MUST NOT look like a tappable button（MUST NOT use the filled/glass outlined button chrome with InkWell）. It MUST present as a status label with a **light gray** background and **black / onSurface** text（MUST NOT use tier accent for footer fill or label color）. Labels MUST be：基础版 slide always「正在使用」（including when the user already has Pro）；Pro when time-valid unlocked「正在使用」；otherwise Pro「敬请期待」. Idea collection CTAs（「我有想法」/「我有更多想法」）MUST live **inside** the Pro card (or open a separate compose sheet) and MUST NOT replace these footer status labels. The client MUST NOT show「当前可用」on this wall. The 基础版 slide title MUST be「基础版」（MUST NOT「免费版」）.

本版墙内 MUST NOT 提供 Pro 试用/支付 CTA；卡外脚 MUST 保持浅灰底黑字「正在使用」/「敬请期待」状态标签；想法入口 MUST 在卡内（或独立 Sheet），MUST NOT 替换卡外脚；MUST NOT「当前可用」；标题 MUST NOT「免费版」。

#### Scenario: 基础版脚恒正在使用

- **WHEN** 用户已开通 Pro 并滑到基础版档
- **THEN** 基础版档脚 MUST 显示「正在使用」且不可点、非按钮形态
- **AND** 该档标题 MUST 为「基础版」

#### Scenario: Pro 未开通敬请期待

- **WHEN** Pro 未开通
- **THEN** Pro 档脚 MUST 显示「敬请期待」且不可点、非按钮形态

#### Scenario: Pro 已开通正在使用

- **WHEN** `predict_capability_pro` 有效开通
- **THEN** Pro 档脚 MUST 显示「正在使用」且不可点、非按钮形态

#### Scenario: Ideas CTA not footer

- **WHEN** 用户要提交想法
- **THEN** 入口 MUST 来自卡内「我有想法」或「我有更多想法」（打开 Sheet）
- **AND** MUST NOT 将卡外脚改为可点「提交意见」

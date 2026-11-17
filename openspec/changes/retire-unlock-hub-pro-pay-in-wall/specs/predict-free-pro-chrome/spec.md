## ADDED Requirements

### Requirement: Pro wall footer SHALL pay in-wall without hub or invite

When the Free/Pro tier wall shows the Pro card and the footer would previously navigate to the unlock hub for payment（eligible, not unlocked, payment product available, trial not taking precedence）, the client MUST present an in-wall payment confirmation（price and duration from catalog product）and, on confirm on non-Web App builds, MUST call the existing feature payment purchase path for that Pro product. The client MUST NOT `push` `/features/unlock` or any feature-unlock hub. The Pro wall and next-3-hours chrome MUST NOT offer invite-code redemption or「如何获取邀请码」as a Pro unlock path. Trial CTA（when `trialAvailable`）MUST remain in-wall via `trial/start`. Web MUST NOT complete a real purchase（same constraint as former hub）. After successful purchase the client MUST refresh catalog so the Pro footer reflects unlocked.

Pro 墙可付费时 MUST 墙内确认并支付；MUST NOT 跳转开通中心；MUST NOT 邀请码开通；试用仍墙内；Web MUST NOT 真付；支付成功 MUST 刷新 catalog。

#### Scenario: 立即开通墙内付费

- **WHEN** 用户在 Pro 卡点「立即开通」且 eligibility 通过且存在可售 product
- **THEN** 客户端 MUST 展示墙内支付确认（含价格）
- **AND** 确认后在 App 上 MUST 发起该 product 购买
- **AND** MUST NOT 导航至 `/features/unlock`

#### Scenario: 无邀请码开通

- **WHEN** 用户打开免费/Pro 两档墙
- **THEN** UI MUST NOT 展示「输入邀请码」或进入邀请码 howto 作为 Pro 开通手段

#### Scenario: 试用仍在墙内

- **WHEN** Pro 未开通、eligibility 通过且 `trialAvailable`
- **THEN** 底栏 MUST 可「开通试用」且 MUST 墙内调用 trial/start（不经 Hub）

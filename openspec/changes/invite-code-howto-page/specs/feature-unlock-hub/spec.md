## ADDED Requirements

### Requirement: Unlock hub invite dialog uses shared component and how-to entry
On the feature unlock hub, when a catalog item supports `invite_code`, the client MUST open the shared invite-code dialog from `app/lib/ui/feature_unlock/` (not a hub-private duplicate). The left action MUST be「获取邀请码」and MUST navigate to the「如何获取邀请码」screen. Confirm MUST redeem via existing invite-codes/redeem with the row `featureId` when the popped code is non-empty. When the user confirms with an empty code, the client MUST silently dismiss without redeem and without navigation. The hub MUST NOT show a page-level WeChat group QR block. 开通中心邀请码必须用共享弹窗；左键获取邀请码进如何获取页；非空码兑换；空码静默关闭；页级微信群 QR 不得再出现在开通中心。

#### Scenario: Get invite code from hub dialog
- **WHEN** the user opens「输入邀请码开通」on a hub card and taps「获取邀请码」
- **THEN** the client MUST open the「如何获取邀请码」screen

#### Scenario: Empty redeem on hub is silent
- **WHEN** the user taps confirm/兑换 on the hub invite dialog with an empty code
- **THEN** the client MUST close the dialog without calling redeem and without navigating away

#### Scenario: Non-empty redeem unchanged
- **WHEN** the user submits a non-empty invite code for a hub feature row
- **THEN** the client MUST call invite-codes/redeem with that row’s `featureId`

#### Scenario: Hub has no page-level QR
- **WHEN** the user opens `/features/unlock` and catalog has a non-empty `inviteGroupQrUrl`
- **THEN** the hub list page MUST NOT render a page-level「加入微信群获取邀请码」QR block

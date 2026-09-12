## ADDED Requirements

### Requirement: How-to page explains invite code sources and acquisition paths
The client SHALL provide a dedicated screen titled「如何获取邀请码」that explains invite-code sources and acquisition methods. The page MUST state that users who have activated the square can view their own invite code on 广场 → 我的 for others to redeem. The page MUST offer method 1: enter the square to obtain a code from other users, with a button that closes the how-to page and clears the feature-unlock hub from the navigation stack by navigating to `/home` and requesting `HomePagerPage.ucg`. The page MUST offer method 2: join the official WeChat group, shown only when catalog `inviteGroupQrUrl` is non-empty after URL resolution, including the QR image (tap opens fullscreen lightbox). When `inviteGroupQrUrl` is empty or the image fails to load, method 2 MUST NOT be shown (or the QR block MUST be fully hidden). UCG eligibility MUST NOT be pre-checked on this button; unqualified users MUST still land on the UCG pager page and be blocked by the existing eligibility shell. 客户端必须提供标题为「如何获取邀请码」的独立页：说明广场激活用户可在广场→我的查看邀请码；方式 1 进广场拿码（按钮清掉 howto 与开通中心栈，go `/home` 并切 UCG）；方式 2 仅当 `inviteGroupQrUrl` 非空展示微信群二维码（失败整块隐藏）；进广场不做资格预检。

#### Scenario: Page title and source copy
- **WHEN** the user opens the invite how-to screen
- **THEN** the AppBar or page title MUST be「如何获取邀请码」
- **AND** the body MUST explain that activated square users can find their invite code under 广场 → 我的

#### Scenario: Enter square clears hub stack
- **WHEN** the user taps「进入广场」（或等价文案）on the how-to page, possibly after opening how-to from the unlock hub
- **THEN** the client MUST navigate such that neither the how-to page nor `/features/unlock` remains on the stack
- **AND** MUST show the home shell on the UCG page index

#### Scenario: WeChat group only when QR URL present
- **WHEN** catalog `inviteGroupQrUrl` is non-empty and the image loads
- **THEN** the how-to page MUST show the WeChat group acquisition method with the QR image

#### Scenario: No QR when URL empty
- **WHEN** `inviteGroupQrUrl` is missing or empty
- **THEN** the how-to page MUST NOT show the WeChat group QR block

#### Scenario: Unqualified UCG still switches page
- **WHEN** the user is not UCG-qualified and taps enter-square
- **THEN** the client MUST still switch to the UCG home page index
- **AND** the existing eligibility UI MUST block square content (no extra gate on the how-to page)

### Requirement: Shared invite-code dialog lives in feature_unlock UI module
The client SHALL implement a shared glass invite-code input dialog under `app/lib/ui/feature_unlock/` for both the feature unlock hub and the prediction slot-full flow. The dialog MUST accept injectable title, body/subtitle, and confirm-button label. The left action MUST be labeled「获取邀请码」and MUST return a distinct how-to result (not a redeem code). The confirm action MUST pop the trimmed input string (including empty). The `TextEditingController` MUST be owned and disposed by the dialog body `State` (MUST NOT dispose after `await show*` returns). Hub and prediction screens MUST use this shared dialog rather than private duplicate widgets. 共享邀请码弹窗必须落在 `app/lib/ui/feature_unlock/`；标题/正文/确认文案可注入；左键「获取邀请码」；确认弹出修剪后字符串；controller 归弹层 State。

#### Scenario: How-to action from dialog
- **WHEN** the user taps「获取邀请码」in the shared dialog
- **THEN** the dialog MUST close with a how-to result
- **AND** the caller MUST navigate to the「如何获取邀请码」screen

#### Scenario: Confirm returns trimmed code
- **WHEN** the user taps the confirm button with input「  ABC  」
- **THEN** the dialog MUST pop with「ABC」

#### Scenario: Empty confirm still pops empty string
- **WHEN** the user taps confirm with empty input
- **THEN** the dialog MUST pop with an empty string (caller decides silent dismiss vs navigate)

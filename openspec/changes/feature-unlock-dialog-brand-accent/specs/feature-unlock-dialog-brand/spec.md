## ADDED Requirements

### Requirement: Unlock-family glass confirm buttons SHALL use feature accent when provided

When a feature-unlock family glass dialog receives a non-null feature accent (`eventAccent` / resolved catalog color), the primary confirm `FilledButton` background MUST use that accent (falling back to `ColorScheme.primary` when accent is null). The button foreground MUST remain `ColorScheme.onPrimary`. This MUST apply to the shared invite-code dialog, `showGlassConfirmDialog`, and the feature-unlock hub payment confirm dialog. Secondary actions (取消 / 获取邀请码) MUST NOT switch to the feature accent. Dialogs that do not pass an accent MUST keep theme primary. 功能开通家族玻璃弹窗在传入功能色时，主确认钮背景 **必须** 使用该色（空则主题 primary）；前景 **必须** 仍为 onPrimary；次要操作不得跟功能色。

#### Scenario: Invite dialog confirm uses accent

- **WHEN** `showInviteCodeDialog` is opened with a non-null `eventAccent`
- **THEN** the confirm FilledButton background MUST equal that accent
- **AND** the「获取邀请码」TextButton MUST NOT use that accent as its foreground

#### Scenario: Invite dialog without accent stays theme primary

- **WHEN** `showInviteCodeDialog` is opened without `eventAccent`
- **THEN** the confirm button background MUST use `ColorScheme.primary`

#### Scenario: Glass confirm with accent

- **WHEN** `showGlassConfirmDialog` is opened with a non-null `eventAccent`
- **THEN** the confirm FilledButton background MUST equal that accent

#### Scenario: Hub pay confirm uses feature color

- **WHEN** the unlock hub payment confirm dialog is shown for a catalog item
- **THEN** the confirm FilledButton background MUST use `resolveFeatureColor` for that item (same accent already applied to logo / glass edge)

### Requirement: Shared invite dialog SHALL render catalog logo when logoUrl is provided

The shared invite-code dialog MUST show `FeatureLogo` with the injected `logoUrl` and accent. When `logoUrl` is empty or fails to load, the existing placeholder MUST remain. 共享邀请码弹窗 **必须** 在注入 logoUrl 时展示功能 Logo；空或加载失败时保持占位。

#### Scenario: Logo from catalog URL

- **WHEN** the dialog is opened with a non-empty http(s) `logoUrl` and an accent
- **THEN** FeatureLogo MUST attempt to load that URL
- **AND** MUST tint / placehold with the provided accent when falling back

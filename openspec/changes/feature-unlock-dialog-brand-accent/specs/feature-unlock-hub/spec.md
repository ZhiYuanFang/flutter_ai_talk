## ADDED Requirements

### Requirement: Hub pay and ad confirm dialogs MUST tint confirm buttons with feature color

On the feature unlock hub, when opening the payment confirm dialog or the ad confirm dialog for a catalog row, the client MUST pass `resolveFeatureColor` for that row as `eventAccent`. The payment confirm dialog’s confirm FilledButton background MUST use that accent (not a hard-coded theme primary while accent is available). The ad confirm path MUST rely on `showGlassConfirmDialog` consuming the same accent for its confirm button. 开通中心支付 / 广告确认 **必须** 传入该行功能色，且确认钮背景 **必须** 使用该色。

#### Scenario: Pay confirm button matches row accent

- **WHEN** the user opens支付开通 confirm for a catalog item with a valid color
- **THEN** glass edge, FeatureLogo, and confirm button background MUST share that resolved feature color

#### Scenario: Ad confirm button matches row accent

- **WHEN** the user opens看广告开通 confirm for a catalog item with a valid color
- **THEN** the confirm button background MUST use that resolved feature color

### Requirement: Hub feature card CTAs and status copy MUST use feature accent; title and description MUST NOT

On each feature unlock hub card, interactive CTAs (支付 / 看广告 / 输入邀请码激活，including prediction per-unit price label) and status copy (activation badge such as「已激活 N」/「已全部激活」, and entitlement remaining lines such as「永久」or remaining-days suffix) MUST use the row’s resolved feature accent for text and outlined-button border/foreground. The feature title and description MUST continue to use the neutral shell foreground (`onShell` / equivalent) and MUST NOT switch to the feature accent. Page-level chrome (AppBar, empty/error list copy) is out of scope for this requirement. 开通中心功能卡内 CTA 与状态文案 **必须** 跟该行功能色；标题与介绍 **必须** 保持中性字色、不得跟功能色。

#### Scenario: CTA outlined buttons tinted

- **WHEN** a locked (or prediction-accumulating) catalog row shows unlock CTAs
- **THEN** each OutlinedButton’s foreground and border MUST use that row’s resolved feature color

#### Scenario: Status badge and remaining copy tinted

- **WHEN** a row shows an activation badge or an entitlement remaining status line
- **THEN** that status text color MUST use the row’s resolved feature accent (MAY use reduced alpha for non-complete badges)

#### Scenario: Title and description stay neutral

- **WHEN** a catalog row is rendered on the unlock hub
- **THEN** the title and description text colors MUST remain the neutral shell foreground
- **AND** MUST NOT equal the feature accent solely for branding

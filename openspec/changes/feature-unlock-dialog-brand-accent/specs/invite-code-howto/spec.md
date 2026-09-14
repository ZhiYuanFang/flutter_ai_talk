## ADDED Requirements

### Requirement: Shared invite-code dialog MUST consume optional brand accent and logo

The shared glass invite-code dialog under `app/lib/ui/feature_unlock/` MUST accept optional `eventAccent` and `logoUrl` parameters (in addition to injectable title, body, and confirm label). When provided, the dialog MUST pass `eventAccent` to the glass shell and FeatureLogo, and MUST use that accent for the confirm FilledButton background (`ColorScheme.primary` when null). Existing how-to / confirm / empty-code pop semantics MUST remain unchanged. 共享邀请码弹窗 **必须** 支持可选功能色与 logo；有色时玻璃边、Logo、确认钮跟色；业务结果语义不变。

#### Scenario: Brand parameters forwarded

- **WHEN** a caller opens the shared dialog with `eventAccent` and `logoUrl`
- **THEN** the glass panel MUST receive that accent
- **AND** FeatureLogo MUST receive that logoUrl and accent
- **AND** the confirm button background MUST use that accent

#### Scenario: Controller lifecycle unchanged

- **WHEN** the shared invite dialog is shown
- **THEN** the TextEditingController MUST still be owned and disposed by the dialog body State

## REMOVED Requirements

### Requirement: Hub feature card CTAs and status copy MUST use feature accent; title and description MUST NOT

**Reason**: 与 AI 分析 Hub 字色政策对齐；标题与介绍改为必须跟功能色（方案 A）。

**Migration**: 见同文件 ADDED「Hub feature card title, description, CTAs and status MUST use feature accent」。

## ADDED Requirements

### Requirement: Hub feature card title, description, CTAs and status MUST use feature accent

On each feature unlock hub card, the feature title, description, interactive CTAs (支付 / 看广告 / 输入邀请码激活，including prediction per-unit price label), and status copy (activation badge such as「已激活 N」/「已全部激活」, and entitlement remaining lines such as「永久」or remaining-days suffix) MUST use the row’s resolved feature accent for text (and for outlined-button border/foreground on CTAs). Title MAY use full accent; description and secondary status MAY use reduced alpha of the same accent. Page-level chrome (AppBar, empty/error list copy) remains out of scope. 开通中心功能卡内标题、介绍、CTA 与状态文案 **必须** 跟该行功能色；页级壳文案不在本 Requirement 范围。

#### Scenario: Pay CTA matches row accent

- **WHEN** a catalog row shows a payment OutlinedButton
- **THEN** that button’s foreground and border MUST use the row’s resolved feature accent

#### Scenario: Activation badge matches row accent

- **WHEN** a prediction row shows an activation badge or an unlocked non-prediction row shows「已全部激活」
- **THEN** that status text color MUST use the row’s resolved feature accent (MAY use reduced alpha for non-complete badges)

#### Scenario: Title and description match row accent

- **WHEN** a feature unlock hub card is rendered with a resolved feature accent
- **THEN** the feature title text color MUST use that accent
- **AND** the description text color MUST use that accent (MAY use reduced alpha)
- **AND** MUST NOT remain neutral `onShell` solely to avoid branding

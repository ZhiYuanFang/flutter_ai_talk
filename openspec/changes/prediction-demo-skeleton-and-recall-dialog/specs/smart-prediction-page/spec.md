## MODIFIED Requirements

### Requirement: Tapping prediction header avatar SHALL open baby profile editor

Only the baby avatar hit target on the prediction header SHALL navigate to the app settings route (`/settings`). Tapping nickname or age text MUST NOT open settings solely for that tap. Unauthenticated users MUST follow the same login gate as other settings entries. This **replaces** the prior requirement that the avatar open `/settings/baby`.

仅头像热区 **必须** 进入设置总页 `/settings`；点击昵称/月龄 **不得** 仅因此进入设置；未登录 **必须** 与设置入口同一登录门；本要求 **取代** 头像进入 `/settings/baby` 的既有约定。

#### Scenario: 点击头像进设置

- **WHEN** 已登录用户在预测顶栏点击宝宝头像
- **THEN** 客户端 MUST 打开 `/settings`

#### Scenario: 点击昵称不进设置

- **WHEN** 用户点击预测顶栏昵称或月龄文案（非头像）
- **THEN** 客户端 MUST NOT 仅因此打开 `/settings`

#### Scenario: 未登录点头像

- **WHEN** 未登录用户点击预测顶栏头像
- **THEN** 客户端 MUST 走与设置入口一致的登录引导（如 `/login`）

## REMOVED Requirements

### Requirement: While recall onboarding is visible chrome panels MUST be hidden

**Reason**: 量身定做改为 Dialog 叠加；底层改为冷态骨架并保留假「值得留意」占位，不再在引导期间隐藏主 chrome。

**Migration**: 见本 change `prediction-recall-onboarding` Dialog 与 `prediction-demo-skeleton` / 冷态 care-alert 占位要求。

## ADDED Requirements

### Requirement: Cold prediction page SHALL keep identity header over skeleton

In cold demo states, the smart prediction page SHALL keep the baby identity header (avatar, nickname, age placeholders as applicable) while showing skeleton rows and the fixed healthy care-alert card. Layout toggle MAY remain.

冷态下预测页 **必须** 保留身份顶栏，并同时展示骨架行与固定健康留意卡；布局切换 MAY 保留。

#### Scenario: 冷态顶栏与骨架同屏

- **WHEN** 智能预测页处于冷态骨架模式
- **THEN** UI MUST 展示身份顶栏
- **AND** MUST 展示骨架预测行
- **AND** MUST 展示固定健康值得留意卡

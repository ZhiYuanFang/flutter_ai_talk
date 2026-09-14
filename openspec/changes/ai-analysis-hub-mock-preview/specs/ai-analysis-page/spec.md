## ADDED Requirements

### Requirement: Hub capability cards SHALL show branded mock preview samples

On the AI analysis Hub, each of the feeding-analysis and growth-trajectory cards MUST show a mock preview sample (not the former plain product blurb) inside a rounded panel filled with a light tint of that card’s feature accent. Each sample body MUST be at most 50 characters (including punctuation and emoji), MUST include emoji, and MUST render at least one emphasized keyword in bold via rich text (`Text.rich` / equivalent). The sample body text color MUST use a deepened feature accent (full accent or slightly darkened), not a washed-out high-alpha tint alone. Immediately above the sample panel and still inside the glass card (below the title row), near the sample’s top-leading corner, the client MUST show a mock-content badge stating that the content is simulated and that the user can obtain such effects; the badge MUST NOT sit outside the glass card. The badge text color MUST use the same deepened feature accent. The same mock preview and badge MUST appear for locked, unlocked, and (for feeding) not-yet-qualified states. AI 分析 Hub 两卡 **必须** 展示浅功能色底的模拟样张（≤50 字、含 emoji、关键字加粗、字色加深）；模拟角标 **必须** 在样张面板外侧左上（玻璃卡内），**不得** 在整卡外侧；各开通态均展示。

#### Scenario: Feeding mock preview

- **WHEN** the Hub feeding card is shown
- **THEN** its sample panel MUST use a light care-alert feature accent background
- **AND** the sample MUST emphasize at least one bold keyword and include emoji with deepened accent text color
- **AND** a badge above the sample panel (inside the glass card) MUST indicate simulated content / obtainable effect
- **AND** that badge MUST NOT be placed outside the glass card

#### Scenario: Growth mock preview

- **WHEN** the Hub growth card is shown
- **THEN** its sample panel MUST use a light growth feature accent background
- **AND** the sample MUST emphasize at least one bold keyword and include emoji with deepened accent text color
- **AND** a badge above the sample panel (inside the glass card) MUST indicate simulated content / obtainable effect
- **AND** that badge MUST NOT be placed outside the glass card

### Requirement: Hub card entitlement remaining copy SHALL sit beside the title; in-card copy SHALL use feature accent

On Hub capability cards, remaining entitlement copy from `featureHubEntitlementRemainingCopy` (when non-empty) MUST be shown as small text on the trailing side of the title row (before any chevron), and MUST NOT be the primary presentation via the former entitlement `metaLines` slot. Title text, mock sample text, entitlement small text, and Hub body prompts (including unlock heartbeat and enter hints) MUST use the card’s feature accent (not neutral onGlass / theme primary alone). Feeding eligibility progress shown on the Hub feeding card MUST also emphasize using that card’s feature accent. Hub 卡剩余时效 **必须** 在标题右侧小字；卡内文案与喂养资格进度 **必须** 跟功能色。

#### Scenario: Remaining days by title

- **WHEN** an unlocked Hub card has non-empty entitlement remaining copy
- **THEN** that copy MUST appear as small text beside the title
- **AND** MUST NOT rely on the old below-blurb entitlement meta line as the sole placement

#### Scenario: In-card copy tinted

- **WHEN** a Hub capability card is rendered with a resolved feature accent
- **THEN** title, mock sample, entitlement small text, and body prompts MUST use that accent
- **AND** feeding eligibility progress on the feeding card MUST use that accent for its emphasis colors

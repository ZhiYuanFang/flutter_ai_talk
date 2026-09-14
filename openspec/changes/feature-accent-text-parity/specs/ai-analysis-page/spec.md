## ADDED Requirements

### Requirement: Feeding and growth workspace in-card copy SHALL use feature accent

On the feeding-analysis workspace and the growth-trajectory workspace, primary in-content copy that describes the capability or guides the user (card/module title on the feeding glass card, product blurb / intro panel text, muted loading or empty prompts, unlock prompts, and growth session prompt / thinking / muted states) MUST use the corresponding catalog feature accent from `resolveFeatureColor` (care-alert for feeding, growth for growth). Text on light tinted panels MUST use a deepened accent (full accent or slightly darkened), not a washed-out high-alpha tint alone. Secondary lines MAY use reduced alpha of the same accent. Glass shell recipe, page background gradient structure, navigation, and business flows MUST remain unchanged by this requirement. 喂养 / 成长工作台页内引导与状态文案 **必须** 跟对应功能色；浅底正文 **必须** 加深可读；**不得** 借此改壳配方或业务流。

#### Scenario: Feeding workspace title and muted use care-alert accent

- **WHEN** the feeding analysis workspace is shown with a resolved care-alert feature accent
- **THEN** the in-card title and muted / unlock prompt copy MUST use that accent (deepened where on a light panel)
- **AND** MUST NOT rely solely on neutral `onGlass` / theme primary for those lines

#### Scenario: Feeding blurb uses accent tint text

- **WHEN** the feeding workspace intro blurb panel is shown
- **THEN** its body text color MUST use the care-alert feature accent (deepened as needed for contrast)

#### Scenario: Growth workspace copy uses growth accent

- **WHEN** the growth trajectory workspace is shown with a resolved growth feature accent
- **THEN** intro blurb text and muted / thinking / question prompt copy MUST use that accent (deepened where on a light panel)
- **AND** page gradient / AppBar layout structure MUST remain as before this requirement

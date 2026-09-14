## ADDED Requirements

### Requirement: Growth workspace session chrome copy SHALL follow growth feature accent

While the growth-trajectory session UI is visible on its workspace route, user-facing session chrome copy (intro blurb, locked/empty muted hints, thinking pane text, question prompt text) MUST use the growth catalog feature accent from `resolveFeatureColor` for `growth_trajectory_predict`. Copy on light panels MUST remain readable via full or slightly deepened accent. This requirement MUST NOT change SSE / Q&A / unlock / daily-limit behavior, and MUST NOT require converting the page into a Hub-style glass card. 成长工作台会话 chrome 文案 **必须** 跟成长功能色；**不得** 改变会话业务或强制改成 Hub 玻璃卡结构。

#### Scenario: Locked growth hint uses accent

- **WHEN** growth is not effectively unlocked and the locked hint is shown
- **THEN** that hint text color MUST use the growth feature accent

#### Scenario: Asking prompt uses accent

- **WHEN** the workspace is in asking phase with a question prompt
- **THEN** the prompt text color MUST use the growth feature accent

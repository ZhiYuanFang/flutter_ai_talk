## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with **exactly three** pages when `kUcgHomePagerEnabled` is true: index 0 feeding `HomeScreen`, index 1 smart prediction (default landing / home hub), index 2 UCG shell. The client MUST allow horizontal navigation into UCG and MUST mount `UcgShell` on first navigation to the UCG index (lazy mount MAY remain). `requestPage(ucg)` MUST animate to the UCG page. Switching pages MUST NOT destroy feeding/prediction State (`AutomaticKeepAliveClientMixin` or equivalent). Android back from UCG MUST return to prediction (home hub) rather than exiting. This requirement supersedes the temporary two-page pause gate from `pause-ucg-vip-slim-prediction-chrome`.

当 `kUcgHomePagerEnabled` 为 true 时，`/home` SHALL 使用三页 PageView：0 喂养、1 智能预测（默认着陆）、2 UCG；**必须** 允许横滑进入并懒挂载 `UcgShell`；本 Requirement **supersede** 暂停期两页闸门。

#### Scenario: 默认进入预测页且可进 UCG

- **WHEN** 用户导航至 `/home` 且 UCG 主壳闸门已翻回
- **THEN** PageView SHALL 显示 page 1（智能预测）
- **AND** PageView itemCount MUST 为 3
- **AND** 用户横滑向 UCG 方向 MUST 能进入 page 2（门槛浮层见 `ucg-entry-gate`）

#### Scenario: requestPage 可进 UCG

- **WHEN** 业务调用 `requestPage(HomePagerPage.ucg)` 且闸门已翻回
- **THEN** 主壳 MUST 切到 UCG 页，不得强制落到预测页

#### Scenario: UCG 返回预测

- **WHEN** 用户在 UCG 页触发返回主页（系统返回或壳内返回/闸门「返回预测页」）
- **THEN** PageView SHALL animateTo page 1（智能预测）

#### Scenario: 从喂养返回预测

- **WHEN** 用户在喂养页触发返回主页（系统返回）
- **THEN** PageView SHALL animateTo page 1（智能预测）

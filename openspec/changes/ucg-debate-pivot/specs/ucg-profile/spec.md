## ADDED Requirements

### Requirement: Profile timeline debate cards SHALL navigate to detail on tap

Tapping a **debate** post card on profile timeline (self or others) MUST open `UcgPostDetailScreen`. VS bar on timeline MUST use `interactive=false`. Tapping **moment** media on profile MAY continue to navigate to detail per baseline.

个人时间线点击辩论帖 MUST 进详情；VS 条 `interactive=false`。

#### Scenario: 点击时间线辩论帖

- **WHEN** 用户在个人主页点击 debate 卡片非头像区域

- **THEN** App SHALL push `UcgPostDetailScreen(postId)`

#### Scenario: 时间线 VS 不可投票

- **WHEN** 用户在个人时间线查看 debate VS 条

- **THEN** `UcgDebateVsBar` SHALL `interactive=false`

### Requirement: Profile header SHALL show force tier icon left of following count

On `UcgUserProfileScreen`, when `forceValue >= 500`, the client MUST render the tier icon immediately left of the「关注 N」label. When `forceValue < 500`, MUST NOT render icon or placeholder.

个人页原力图标 MUST 在「关注 N」左侧；低于 500 无展示。

#### Scenario: 个人页青铜图标

- **WHEN** 用户 `forceValue` 为 600

- **THEN** 个人页 SHALL 在「关注 N」左侧展示对应档位图标

## MODIFIED Requirements

### Requirement: Feed avatar tap SHALL open UcgUserProfileScreen for all authors including self

Tapping the author avatar on square Feed cards MUST navigate to `UcgUserProfileScreen(userId: authorId)` for every author. Square debate cards MUST show `forceTier` icon beside nickname when tier ≥ bronze. The App MUST NOT switch Shell tab to 我的 for self avatar tap.

广场卡片头像统一进 profile；昵称旁展示原力图标（≥青铜）。

#### Scenario: 点击他人头像

- **WHEN** 用户在广场 Feed 点击帖子作者头像且作者非本人

- **THEN** App SHALL push `UcgUserProfileScreen(userId: authorId)`

#### Scenario: 作者行原力图标

- **WHEN** 帖子作者 `forceValue` ≥ 500

- **THEN** 广场卡片作者行 SHALL 在昵称旁展示档位图标

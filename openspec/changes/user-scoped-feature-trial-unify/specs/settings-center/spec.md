## ADDED Requirements

### Requirement: Settings SHALL show feature-unlock card below baby card when logged in
When the user is logged in, the settings center SHALL show a「功能开通」card below the baby profile card; tapping it MUST navigate to `/features/unlock`. The settings UI MUST NOT show the previous unlock summary copy under the baby avatar as the primary unlock entry. 登录后设置中心 **必须** 在宝宝卡片下方提供「功能开通」卡片入口，**不得** 再以头像下开通摘要作为主入口。

#### Scenario: Logged-in entry
- **WHEN** 已登录用户打开设置中心
- **THEN** 宝宝卡片下方 MUST 出现「功能开通」卡片；点击 MUST 进入 `/features/unlock`

#### Scenario: Logged-out hidden
- **WHEN** 未登录用户打开设置中心
- **THEN** MUST NOT 展示该「功能开通」卡片

#### Scenario: Avatar summary removed
- **WHEN** 已登录用户查看宝宝头像区域
- **THEN** MUST NOT 再展示原「已开通 N 项 / 去开通」类头像下摘要作为开通入口

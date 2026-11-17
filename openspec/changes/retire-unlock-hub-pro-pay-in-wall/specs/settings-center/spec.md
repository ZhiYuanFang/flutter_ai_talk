## MODIFIED Requirements

### Requirement: Settings SHALL show feature-unlock card below baby card when logged in

When the user is logged in, the settings center MUST NOT show a「功能开通」card below the baby profile card and MUST NOT navigate to `/features/unlock` from settings. The settings UI MUST NOT restore the previous unlock summary copy under the baby avatar as an unlock entry. Pro unlock entry MUST be via the next-3-hours Free/Pro wall only（see `predict-free-pro-chrome`）.

登录后设置中心 **不得** 再展示「功能开通」卡或跳转开通中心；**不得** 恢复头像下开通摘要；Pro 开通入口 **必须** 仅经 3h 两档墙。

#### Scenario: Logged-in no unlock card

- **WHEN** 已登录用户打开设置中心
- **THEN** 宝宝卡片下方 MUST NOT 出现「功能开通」卡片

#### Scenario: Logged-out hidden

- **WHEN** 未登录用户打开设置中心
- **THEN** MUST NOT 展示该「功能开通」卡片

#### Scenario: Avatar summary removed

- **WHEN** 已登录用户查看宝宝头像区域
- **THEN** MUST NOT 再展示原「已开通 N 项 / 去开通」类头像下摘要作为开通入口

## ADDED Requirements

### Requirement: Settings center MUST retain clear history media cache entry

The settings center MUST continue to expose「清除历史媒体缓存」for logged-in users with confirmation, clearing only `EventMediaLocalStore` history media copies/mappings. Account switch / wipe MUST NOT be required to clear that media cache as part of this change. 设置中心 **必须** 保留「清除历史媒体缓存」入口；本变更 **不得** 以切号 wipe 替代该入口。

#### Scenario: 清媒体入口仍在

- **WHEN** 已登录用户打开设置中心
- **THEN** UI MUST 仍可进入「清除历史媒体缓存」确认与清理流程

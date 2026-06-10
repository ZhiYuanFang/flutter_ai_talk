## ADDED Requirements

### Requirement: Profile without treasure tab SHALL have zero TabBar placeholder height

When `kUcgTreasureEnabled` is false, the profile shell MUST NOT reserve vertical space for a removed `TabBar` or empty `TabBarView` between the profile header card and the posts list. The posts list MUST begin immediately below the header card within normal layout padding.

宝藏 Tab 关闭时，资料卡与动态列表之间 MUST NOT 保留 TabBar 占位空白。

#### Scenario: 资料卡与动态列表间距正常
- **WHEN** `kUcgTreasureEnabled` 为 false 且用户打开我的 Tab 资料页
- **THEN** 动态列表顶部与资料卡底部之间 SHALL NOT 出现大块空白（原 TabBar 高度量级）
- **AND** `NestedScrollView.body` SHALL 直接挂载动态列表

#### Scenario: 操作按钮不被列表遮挡
- **WHEN** 用户位于资料页顶部且宝藏关闭
- **THEN** 资料卡内关注/私信/编辑等操作区 SHALL 仍完整可点
- **AND** 动态列表 SHALL NOT 覆盖资料卡操作行

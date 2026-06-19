## ADDED Requirements

### Requirement: Enter-square pull tab SHALL show UCG unread indicator on feeding page

While `UcgHomeShell` PageView is on page 0, the right-edge「进入广场」expandable pull tab MUST display an unread highlight (dot or badge) at the top-left of its icon when `ucgUnreadCountProvider` (or equivalent) is greater than zero. Unread count MUST follow the same OR logic as UCG shell message tab: sum of conversation unread plus comment notification unread.

喂养页（page 0）右侧「进入广场」拉条在存在 UCG 未读（会话未读 + 互动消息未读）时，必须在图标左上角展示未读高亮点，计数逻辑与 UCG 消息 Tab 一致。

#### Scenario: 有未读时喂养页拉条显示红点

- **WHEN** 已登录用户有未读私信或未读互动消息且停留在喂养 page 0
- **THEN** 「进入广场」拉条图标左上角 SHALL 显示未读指示点
- **AND** 指示 SHALL 在 `ucgUnreadCountProvider > 0` 时可见

#### Scenario: 无未读时隐藏红点

- **WHEN** `ucgUnreadCountProvider` 为 0
- **THEN** 拉条 SHALL NOT 显示未读指示点

#### Scenario: WS 推送更新喂养页角标

- **WHEN** 用户停留喂养页且 UCG WebSocket 收到新消息或 `comment_notification`
- **THEN** 未读计数 SHALL 更新
- **AND** 拉条红点 SHALL 在不进入 UCG Shell 的情况下同步显示

#### Scenario: 登录后首次进入喂养页即有未读角标

- **WHEN** 已登录且 wxId 已绑定用户打开喂养页（page 0），且服务端存在未读私信或互动消息
- **THEN** App SHALL 在展示「进入广场」拉条前拉取未读计数
- **AND** `ucgUnreadCountProvider > 0` 时拉条 SHALL 显示红点，无需先进入 UCG Shell

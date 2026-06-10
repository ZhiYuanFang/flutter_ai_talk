## MODIFIED Requirements

### Requirement: User SHALL be able to disable scheduled night sky theme

The app MUST persist a boolean `theme_schedule_enabled` preference. When the preference key is **absent** (never written), the app MUST treat `theme_schedule_enabled` as **`false`**. When `theme_schedule_enabled` is `false`, the app MUST always apply the user's saved theme baseline and MUST NOT force night sky based on local time. When `true`, the existing 19:00–05:00 night sky schedule MUST apply.

应用须持久化「是否启用自动夜空」。**键不存在时默认为关**。关闭后须始终应用用户基线、不得再按本地时间强制夜空；开启时仍按 19:00–05:00 调度。

#### Scenario: 新用户默认关闭自动夜空
- **WHEN** 用户从未写入 `theme_schedule_enabled`
- **THEN** App SHALL 视为自动夜空已关闭
- **AND** 任意本地时间生效主题 SHALL 等于用户主题基线

#### Scenario: 关闭自动夜空后全天基线
- **WHEN** 用户在设置页关闭「自动夜空」
- **THEN** App SHALL 持久化 `theme_schedule_enabled=false`
- **AND** 任意本地时间生效主题 SHALL 等于用户基线（含自定义 seed）

#### Scenario: 重新开启自动夜空
- **WHEN** 用户将「自动夜空」从关切为开
- **THEN** App SHALL 持久化 `theme_schedule_enabled=true`
- **AND** 若当前处于 19:00–05:00 App SHALL 立即应用夜空生效主题

#### Scenario: 已开启用户不受影响
- **WHEN** 磁盘已持久化 `theme_schedule_enabled=true`
- **THEN** App SHALL 继续按 19:00–05:00 调度夜空
- **AND** App MUST NOT 因本变更将已有用户改为关闭

#### Scenario: 开启自动夜空且基线为自定义色
- **WHEN** `theme_schedule_enabled=true` 且持久化基线为自定义 seed（`preset=null`）
- **AND** 本地时间为 10:00（白天窗口）
- **THEN** 生效主题 SHALL 仍为该自定义 seed bundle
- **AND** 本地时间为 21:00 时生效主题 SHALL 为夜空 preset

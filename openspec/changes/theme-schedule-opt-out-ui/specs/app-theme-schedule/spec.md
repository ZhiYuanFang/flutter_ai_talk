## ADDED Requirements

### Requirement: User SHALL be able to disable scheduled night sky theme

The app MUST persist a boolean `theme_schedule_enabled` preference (default `true` when unset). When `theme_schedule_enabled` is `false`, the app MUST always apply the user's saved theme baseline and MUST NOT force night sky based on local time. When `true`, the existing 19:00–05:00 night sky schedule MUST apply.

应用须持久化「是否启用自动夜空」（默认开启）。关闭后须始终应用用户基线、不得再按本地时间强制夜空；开启时仍按 19:00–05:00 调度。

#### Scenario: 默认开启自动夜空
- **WHEN** 用户从未写入 `theme_schedule_enabled`
- **THEN** App SHALL 视为自动夜空已开启
- **AND** 19:00–05:00 仍强制夜空生效主题

#### Scenario: 关闭自动夜空后全天基线
- **WHEN** 用户在设置页关闭「自动夜空」
- **THEN** App SHALL 持久化 `theme_schedule_enabled=false`
- **AND** 任意本地时间生效主题 SHALL 等于用户基线（含自定义 seed）

#### Scenario: 重新开启自动夜空
- **WHEN** 用户将「自动夜空」从关切为开
- **THEN** App SHALL 持久化 `theme_schedule_enabled=true`
- **AND** 若当前处于 19:00–05:00 App SHALL 立即应用夜空生效主题

#### Scenario: 开启自动夜空且基线为自定义色
- **WHEN** `theme_schedule_enabled=true` 且持久化基线为自定义 seed（`preset=null`）
- **AND** 本地时间为 10:00（白天窗口）
- **THEN** 生效主题 SHALL 仍为该自定义 seed bundle
- **AND** 本地时间为 21:00 时生效主题 SHALL 为夜空 preset

## MODIFIED Requirements

### Requirement: App SHALL apply night sky theme during evening hours with unified formula

When `theme_schedule_enabled` is `true`, using the device local timezone, the app MUST apply `ThemePreset.nightSky` visual bundle when local time is in `[19:00, 24:00)` or `[00:00, 05:00)`. Outside that window, the app MUST apply the user's saved theme baseline from settings (`ThemePreferences`). When `theme_schedule_enabled` is `false`, the app MUST NOT apply time-based night sky override. The schedule MUST NOT skip or branch when the user's baseline is already night sky; the same formula applies in all cases (when baseline is night sky, evening application is visually unchanged).

当自动夜空开启时，应用须按设备本地时间统一公式切换：19:00 至次日 05:00 生效夜空；其余时段生效用户基线。自动夜空关闭时不得再按时间强制夜空；用户基线已为夜空时仍走同一调度路径。

#### Scenario: 晚间自动夜空
- **WHEN** `theme_schedule_enabled=true` 且本地时间为 19:00 或之后且早于 24:00
- **THEN** App 全局生效主题 SHALL 使用夜空 preset（`nightSkyBundle`）

#### Scenario: 凌晨仍夜空
- **WHEN** `theme_schedule_enabled=true` 且本地时间为 00:00 至 04:59
- **THEN** App 全局生效主题 SHALL 仍为夜空 preset

#### Scenario: 清晨恢复用户基线
- **WHEN** `theme_schedule_enabled=true` 且本地时间为 05:00 或之后且早于 19:00
- **THEN** App SHALL 应用 `ThemePreferences` 中持久化的 preset/自定义 seed 作为生效主题

#### Scenario: 用户基线已为夜空时晚间无视觉变化
- **WHEN** `theme_schedule_enabled=true` 且用户持久化基线为 `ThemePreset.nightSky` 且本地时间为 20:00
- **THEN** 生效主题 SHALL 仍为夜空 preset
- **AND** App MUST 使用与基线夜空相同的统一调度路径（不得跳过定时分支）

#### Scenario: 关闭自动夜空后晚间不强制
- **WHEN** `theme_schedule_enabled=false` 且本地时间为 21:00
- **THEN** App SHALL 应用用户基线而非强制夜空

### Requirement: User theme settings SHALL persist as baseline unaffected by schedule

Changes in the settings theme picker MUST write to persistent `ThemePreferences` as the user's baseline. Scheduled night overlay MUST NOT overwrite persisted baseline storage. The settings UI selection state MUST reflect the baseline for classic and night sky swatches. When `theme_schedule_enabled` is `true`, the settings UI MUST NOT expose custom color picking controls; existing custom seed on disk MUST remain until the user selects classic or night sky baseline while schedule is off, or selects classic while schedule is on.

设置页改色须写入持久化基线；定时夜空不得覆盖基线存储。自动夜空开启时设置页不得提供自定义选色控件；磁盘上已有自定义 seed 须保留直至用户主动改选经典或夜空（关自动夜空时可选自定义）。

#### Scenario: 设置页改色更新基线
- **WHEN** 用户在设置页选择经典或夜空 preset
- **THEN** App SHALL 持久化该选择作为基线

#### Scenario: 自动夜空开启时不可改自定义色
- **WHEN** `theme_schedule_enabled=true` 且用户打开设置页主题区
- **THEN** UI SHALL NOT 展示彩色 swatch 与 HSV 色盘
- **AND** 用户 SHALL 仍可选择经典或夜空作为基线

#### Scenario: 自动夜空关闭后可选自定义色
- **WHEN** `theme_schedule_enabled=false` 且用户打开设置页主题区
- **THEN** UI SHALL 展示经典、夜空与彩色 swatch
- **AND** 用户 SHALL 可通过色盘选择并持久化自定义 seed

#### Scenario: 开启自动夜空不删除已有自定义基线
- **WHEN** 用户基线已为自定义 seed 且用户保持或开启「自动夜空」
- **THEN** App MUST NOT 仅因开启自动夜空而清除持久化自定义 seed
- **AND** 05:00–19:00 生效主题 SHALL 仍可使用该自定义 seed

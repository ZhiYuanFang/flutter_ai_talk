## ADDED Requirements

### Requirement: App SHALL apply night sky theme during evening hours

Using the device local timezone, the app MUST apply `ThemePreset.nightSky` visual bundle when local time is in `[19:00, 24:00)` or `[00:00, 05:00)`. Outside that window, the app MUST apply the user's saved theme baseline from settings (`ThemePreferences`).

应用须按设备本地时间：19:00 至次日 05:00 展示夜空主题；其余时段展示用户在设置中保存的主题基线。

#### Scenario: 晚间自动夜空
- **WHEN** 本地时间为 19:00 或之后且早于 24:00
- **THEN** App 全局主题 SHALL 使用夜空 preset（`nightSkyBundle`）

#### Scenario: 凌晨仍夜空
- **WHEN** 本地时间为 00:00 至 04:59
- **THEN** App 全局主题 SHALL 仍为夜空 preset

#### Scenario: 清晨恢复用户设置
- **WHEN** 本地时间为 05:00 或之后且早于 19:00
- **THEN** App SHALL 应用 `ThemePreferences` 中持久化的 preset/自定义 seed
- **AND** App MUST NOT 强制夜空

### Requirement: User theme settings SHALL persist as baseline unaffected by schedule

Changes in the settings theme picker MUST write to persistent `ThemePreferences` as the user's baseline. Scheduled night overlay MUST NOT overwrite persisted baseline storage. At 05:00, the app MUST restore display from persisted baseline.

设置页改色须写入持久化基线；定时夜空不得覆盖基线存储；05:00 须从基线恢复展示。

#### Scenario: 设置页改色更新基线
- **WHEN** 用户在设置页选择任意主题或自定义颜色
- **THEN** App SHALL 持久化该选择作为基线
- **AND** 若当前不在夜空时段 App SHALL 立即应用该主题

#### Scenario: 夜空时段手动改色
- **WHEN** 用户在 19:00–05:00 夜空时段于设置页更改主题
- **THEN** App SHALL 更新持久化基线
- **AND** 05:00 后 App SHALL 展示新基线而非旧基线

### Requirement: Theme schedule SHALL re-evaluate on resume and periodic tick

The app MUST re-evaluate scheduled vs baseline theme when the app resumes to foreground and at least once per minute while running, so crossing 19:00 or 05:00 while backgrounded still updates theme promptly.

App 恢复前台与运行中周期检查须重新计算主题，确保跨过 19:00/05:00 后及时切换。

#### Scenario: 后台跨过 19 点
- **WHEN** App 在 18:50 进入后台并于 19:10 恢复前台
- **THEN** App SHALL 在恢复后展示夜空主题

#### Scenario: 后台跨过 5 点
- **WHEN** App 在夜空主题下于 04:50 进入后台并于 05:10 恢复前台
- **THEN** App SHALL 在恢复后展示用户基线主题

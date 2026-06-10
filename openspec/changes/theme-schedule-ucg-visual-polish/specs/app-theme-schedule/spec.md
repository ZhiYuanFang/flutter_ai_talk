## ADDED Requirements

### Requirement: App SHALL apply night sky theme during evening hours with unified formula

Using the device local timezone, the app MUST apply `ThemePreset.nightSky` visual bundle when local time is in `[19:00, 24:00)` or `[00:00, 05:00)`. Outside that window, the app MUST apply the user's saved theme baseline from settings (`ThemePreferences`). The schedule MUST NOT skip or branch when the user's baseline is already night sky; the same formula applies in all cases (when baseline is night sky, evening application is visually unchanged).

应用须按设备本地时间统一公式切换主题：19:00 至次日 05:00 生效夜空；其余时段生效用户基线；不得因用户基线已为夜空而跳过晚间分支。

#### Scenario: 晚间自动夜空
- **WHEN** 本地时间为 19:00 或之后且早于 24:00
- **THEN** App 全局生效主题 SHALL 使用夜空 preset（`nightSkyBundle`）

#### Scenario: 凌晨仍夜空
- **WHEN** 本地时间为 00:00 至 04:59
- **THEN** App 全局生效主题 SHALL 仍为夜空 preset

#### Scenario: 清晨恢复用户基线
- **WHEN** 本地时间为 05:00 或之后且早于 19:00
- **THEN** App SHALL 应用 `ThemePreferences` 中持久化的 preset/自定义 seed 作为生效主题

#### Scenario: 用户基线已为夜空时晚间无视觉变化
- **WHEN** 用户持久化基线为 `ThemePreset.nightSky` 且本地时间为 20:00
- **THEN** 生效主题 SHALL 仍为夜空 preset
- **AND** App MUST 使用与基线夜空相同的统一调度路径（不得跳过定时分支）

### Requirement: User theme settings SHALL persist as baseline unaffected by schedule

Changes in the settings theme picker MUST write to persistent `ThemePreferences` as the user's baseline. Scheduled night overlay MUST NOT overwrite persisted baseline storage. The settings UI selection state MUST reflect the baseline, not the temporary effective night theme.

设置页改色须写入持久化基线；定时夜空不得覆盖基线存储；设置页选中态须展示基线而非临时生效主题。

#### Scenario: 设置页改色更新基线
- **WHEN** 用户在设置页选择经典、夜空或自定义颜色
- **THEN** App SHALL 持久化该选择作为基线

#### Scenario: 夜空时段设置页仍显示基线选中
- **WHEN** 用户基线为自定义浅色且当前生效主题为夜空（21:00）
- **THEN** 设置页 SHALL 显示自定义色为选中状态
- **AND** 设置页 MUST NOT 仅因当前生效夜空而将「夜空」swatch 标为唯一选中（除非基线即为夜空）

#### Scenario: 夜空时段手动改基线
- **WHEN** 用户在 19:00–05:00 于设置页更改主题基线
- **THEN** App SHALL 更新持久化基线
- **AND** 05:00 后 App SHALL 展示新基线

### Requirement: Theme schedule SHALL re-evaluate on resume and periodic tick

The app MUST re-evaluate effective vs baseline theme when the app resumes to foreground and at least once per minute while running.

App 恢复前台与运行中周期检查须重新计算生效主题。

#### Scenario: 后台跨过 19 点
- **WHEN** App 在 18:50 进入后台并于 19:10 恢复前台
- **THEN** App SHALL 在恢复后展示夜空生效主题

#### Scenario: 后台跨过 5 点
- **WHEN** App 在夜空生效主题下于 04:50 进入后台并于 05:10 恢复前台
- **THEN** App SHALL 在恢复后展示用户基线主题

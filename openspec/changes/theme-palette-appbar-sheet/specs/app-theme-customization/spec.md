## MODIFIED Requirements

### Requirement: Settings SHALL offer classic and night sky presets plus arbitrary custom color

The shared theme palette sheet（opened from home-shell palette actions）MUST expose fixed presets for「经典」and「夜空」. When `theme_schedule_enabled` is `false`, the sheet MUST show a custom color picker（HSV or equivalent）by default and MUST allow picking any ARGB color as a custom background seed; selecting or changing a custom color MUST select the「彩色」baseline. When `theme_schedule_enabled` is `true`, custom color picking MUST be unavailable. The app MUST NOT limit custom color selection to a fixed list of six soft swatches. Restoring classic MUST be done by tapping「经典」. The settings screen MUST NOT host this theme preset UI. 公用主题调色 Sheet（自主壳调色盘打开）MUST 提供「经典」与「夜空」。自动夜空关闭时 Sheet MUST 默认展示自定义色盘并允许任选 ARGB；变更自定义色 MUST 选中「彩色」。自动夜空开启时不得提供自定义选色。不得限死六色 soft swatch。恢复经典须点「经典」。设置页 MUST NOT 再承载该主题预设 UI。

#### Scenario: 选择经典

- **WHEN** 用户在公用主题 Sheet 点击「经典」预设
- **THEN** App SHALL 清除自定义 seed 并应用 `classicLightBundle`（按宝宝性别主色）
- **AND** App SHALL 持久化基线

#### Scenario: 选择夜空为基线

- **WHEN** 用户在公用主题 Sheet 点击「夜空」预设
- **THEN** App SHALL 持久化 `ThemePreset.nightSky` 作为基线
- **AND** 若当前不在 19:00–05:00 窗口或自动夜空已关闭 App SHALL 立即展示夜空

#### Scenario: 色盘选择任意色

- **WHEN** `theme_schedule_enabled=false` 且用户在 Sheet 默认可见的色盘中选择或变更颜色
- **THEN** App SHALL 持久化 `preset=null` 与所选 seed
- **AND** App SHALL 根据 seed 亮度推导浅色或深色 shell bundle
- **AND** 「彩色」选中态 SHALL 自动生效

#### Scenario: 自动夜空开启时不提供可用自定义选色

- **WHEN** `theme_schedule_enabled=true` 且用户打开主题 Sheet
- **THEN** UI SHALL NOT 提供可用的自定义选色控件

#### Scenario: 设置页无主题预设区

- **WHEN** 用户打开设置页
- **THEN** UI SHALL NOT 展示原设置页主题预设 swatch / 设置页内主题色盘区块

### Requirement: Settings SHALL expose auto night sky toggle on theme section header

The「自动夜空」toggle MUST appear in the shared theme palette sheet and MUST NOT appear as a settings-page theme section header row. The toggle MUST bind to persisted `theme_schedule_enabled` and MUST immediately update in-memory providers and persist the preference. 「自动夜空」开关 MUST 出现在公用主题调色 Sheet 内，MUST NOT 再作为设置页主题标题行控件。开关 MUST 绑定持久化偏好，切换 MUST 即时生效并写盘。

#### Scenario: Sheet 内展示开关

- **WHEN** 用户打开公用主题 Sheet
- **THEN** Sheet 内 SHALL 显示「自动夜空」与 Switch

#### Scenario: 切换开关持久化

- **WHEN** 用户切换「自动夜空」Switch
- **THEN** App SHALL 写入 `theme_schedule_enabled` 并刷新生效主题

### Requirement: Custom color picker SHALL be collapsible behind a colorful swatch

When `theme_schedule_enabled` is `false`, the shared theme palette sheet MUST show「彩色」alongside「经典」and「夜空」, and MUST show the HSV（or equivalent）color picker by default without requiring a prior tap on「彩色」to expand. Selecting or changing a color in the picker MUST select the custom（彩色）baseline. Selecting classic or night sky MUST update the selected preset chip accordingly. 自动夜空关闭时，公用 Sheet MUST 展示「彩色」与经典/夜空，且色盘 MUST 默认可见（无需先点「彩色」展开）。在色盘选色或改色 MUST 选中彩色基线；选经典或夜空 MUST 更新对应选中态。

#### Scenario: 默认展示色盘

- **WHEN** `theme_schedule_enabled=false` 且用户打开主题 Sheet
- **THEN** 自定义色盘 SHALL 默认可见

#### Scenario: 改色选中彩色

- **WHEN** 用户在默认可见色盘中变更颜色
- **THEN** 「彩色」SHALL 为选中态且基线 SHALL 为自定义 seed

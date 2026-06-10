## ADDED Requirements

### Requirement: Settings SHALL expose auto night sky toggle on theme section header

The theme section header MUST display the label「主题」on the left and an「自动夜空」toggle on the right. The toggle MUST bind to persisted `theme_schedule_enabled` (default on). Toggling MUST immediately update in-memory providers and persist the preference.

设置页「主题」标题行须在右侧提供「自动夜空」开关，绑定持久化偏好（默认开），切换须即时生效并写盘。

#### Scenario: 标题行展示开关
- **WHEN** 用户打开设置页并滚动至主题区
- **THEN** 「主题」标题同一行右侧 SHALL 显示「自动夜空」与 Switch

#### Scenario: 切换开关持久化
- **WHEN** 用户切换「自动夜空」Switch
- **THEN** App SHALL 写入 `theme_schedule_enabled` 并刷新生效主题

### Requirement: Custom color picker SHALL be collapsible behind a colorful swatch

When `theme_schedule_enabled` is `false`, the settings UI MUST show a third「彩色」swatch adjacent to「经典」and「夜空」. The HSV color wheel MUST NOT be visible by default. The first tap on the colorful swatch MUST expand the wheel; a second tap on the same swatch MUST collapse it. Selecting classic or night sky MUST collapse the wheel if expanded.

自动夜空关闭时，须在经典与夜空旁展示「彩色」swatch；HSV 色盘默认收起；点彩色展开、再点收起；选经典或夜空时须收起色盘。

#### Scenario: 默认收起色盘
- **WHEN** `theme_schedule_enabled=false` 且用户刚进入设置页主题区
- **THEN** HSV 色盘 SHALL NOT 默认展开

#### Scenario: 点击彩色展开与收起
- **WHEN** 用户点击「彩色」swatch 且色盘当前收起
- **THEN** App SHALL 展开 HSV 色盘
- **WHEN** 用户再次点击同一「彩色」swatch
- **THEN** App SHALL 收起色盘

#### Scenario: 选经典或夜空收起色盘
- **WHEN** 色盘已展开且用户点击「经典」或「夜空」
- **THEN** App SHALL 收起色盘并更新对应基线

## MODIFIED Requirements

### Requirement: Settings SHALL offer classic and night sky presets plus arbitrary custom color

The theme settings section MUST expose fixed presets for「经典」and「夜空」. When `theme_schedule_enabled` is `false`, the app MUST provide a collapsible color wheel (HSV or equivalent) reachable via the colorful swatch, allowing the user to pick any ARGB color as a custom background seed. When `theme_schedule_enabled` is `true`, custom color picking MUST be unavailable in settings. The app MUST NOT limit custom color selection to a fixed list of six soft swatches. The settings UI MUST NOT include a separate「清除自定义背景」action; restoring classic MUST be done by tapping the「经典」preset.

设置页须保留经典与夜空预设。自动夜空关闭时须通过彩色 swatch 展开色盘任选自定义色；自动夜空开启时不得提供自定义选色。不得再提供独立的「清除自定义背景」入口；恢复经典须通过点击「经典」。

#### Scenario: 选择经典
- **WHEN** 用户点击「经典」预设
- **THEN** App SHALL 清除自定义 seed 并应用 `classicLightBundle`（按宝宝性别主色）
- **AND** App SHALL 持久化基线

#### Scenario: 选择夜空为基线
- **WHEN** 用户点击「夜空」预设
- **THEN** App SHALL 持久化 `ThemePreset.nightSky` 作为基线
- **AND** 若当前不在 19:00–05:00 窗口或自动夜空已关闭 App SHALL 立即展示夜空

#### Scenario: 色盘选择任意色
- **WHEN** `theme_schedule_enabled=false` 且用户在已展开的色盘中选择颜色
- **THEN** App SHALL 持久化 `preset=null` 与所选 seed
- **AND** App SHALL 根据 seed 亮度推导浅色或深色 shell bundle
- **AND** 「彩色」swatch SHALL 显示为选中态

#### Scenario: 自动夜空开启时不展示色盘入口
- **WHEN** `theme_schedule_enabled=true` 且用户打开设置页主题区
- **THEN** UI SHALL NOT 展示「自定义背景色」标题下的常显色盘
- **AND** UI SHALL NOT 展示「彩色」swatch

#### Scenario: 无独立清除自定义背景入口
- **WHEN** 用户打开设置页主题区
- **THEN** UI SHALL NOT 展示「清除自定义背景」ListTile 或等价独立操作

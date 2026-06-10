## ADDED Requirements

### Requirement: Settings SHALL offer classic and night sky presets plus arbitrary custom color

The theme settings section MUST expose fixed presets for「经典」and「夜空」. The app MUST provide a color wheel (HSV or equivalent) allowing the user to pick any ARGB color as a custom background seed. The app MUST NOT limit custom color selection to a fixed list of six soft swatches in the primary settings UI.

设置页须保留经典与夜空快捷预设，并提供颜色选盘供用户选择任意自定义背景色；主设置 UI 不得再将自定义色限制为六个固定浅色块。

#### Scenario: 选择经典
- **WHEN** 用户点击「经典」预设
- **THEN** App SHALL 清除自定义 seed 并应用 `classicLightBundle`（按宝宝性别主色）
- **AND** App SHALL 持久化基线

#### Scenario: 选择夜空为基线
- **WHEN** 用户点击「夜空」预设
- **THEN** App SHALL 持久化 `ThemePreset.nightSky` 作为基线
- **AND** 若当前不在 19:00–05:00 窗口 App SHALL 立即展示夜空

#### Scenario: 色盘选择任意色
- **WHEN** 用户在颜色选盘中选择任意颜色并确认
- **THEN** App SHALL 持久化 `preset=null` 与所选 seed
- **AND** App SHALL 根据 seed 亮度推导浅色或深色 shell bundle
- **AND** 设置页 SHALL 显示该自定义色为选中（非经典/夜空 swatch）

#### Scenario: 移除固定六色 swatch 主入口
- **WHEN** 用户打开设置页主题区
- **THEN** UI SHALL NOT 展示 softBlue…softPurple 六个固定色块作为主候选
- **AND** UI SHALL 展示颜色选盘或等价任意色选择控件

### Requirement: Legacy soft presets SHALL migrate to custom seed on load

When loading persisted preferences where `preset` is one of `softBlue`, `softPink`, `softGreen`, `softYellow`, `softGrey`, or `softPurple`, the app MUST migrate to `preset=null` with `seed` equal to the former swatch color and rewrite storage.

加载旧版 soft preset 时须迁移为自定义 seed 并回写持久化。

#### Scenario: 升级用户 softPink
- **WHEN** 磁盘上存 preset=softPink
- **THEN** 冷启动加载后基线 SHALL 等价于 preset=null 且 seed 为原 softPink 色值
- **AND** App SHALL 回写迁移后的偏好

### Requirement: Female classic primary color SHALL be rose red

When `BabySex.female` and classic light theme applies, `sexPrimary` MUST resolve to rose red (default `#E91E63` unless design specifies otherwise).

女性宝宝经典浅色主题的主色 MUST 为玫瑰红而非原深红常量。

#### Scenario: 女宝经典主题
- **WHEN** 用户基线为经典且宝宝性别为女
- **THEN** 主题 primary 与经典 shell tint SHALL 基于玫瑰红色 seed 推导

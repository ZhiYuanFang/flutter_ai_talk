## MODIFIED Requirements

### Requirement: 深色 shell HSL 推导

When the user seed color has sufficiently low luminance or maps to the night preset, the system MUST derive `shellColor` and `surfaceColor` from the seed via HSL adjustment rather than using a single fixed hex for all users. For non-night-sky dark bundles, the VisualBundle `seedColor` used for chrome tinting（panelGlass / ColorScheme accent role）MUST be a brighter accent derived from the input dark color, structurally matching night sky（page dark, dye brighter）; the night-sky preset MUST keep its fixed shell/surface/accent constants. 当用户种子色亮度低于产品阈值（或选用深色预设）时，系统必须基于种子色 **HSL** 推导 `shellColor` 与 `surfaceColor`（surface 相对 shell 略提亮），**不得**对所有用户写死同一 shell 色值；「夜空」预设除外（见 `theme-settings-presets`）。非夜空暗壳 bundle 用于 chrome 染色的 `seedColor` MUST 为自输入暗色派生的偏亮 accent（页底暗、染料亮，结构对齐夜空）；夜空 MUST 保持固定三色常量。

#### Scenario: 用户选择深紫种子色

- **WHEN** 用户从颜色选择器选取 luminance 低于阈值的自定义色并保存
- **THEN** `isDarkShell` 必须为 true，且 `shellColor` 的色相/饱和度须继承该种子色（亮度钳制在 shell 区间）
- **AND** bundle 的 chrome `seedColor` MUST 为相对 shell 偏亮的 accent（不得与未抬亮的暗壳色相同以致 panelGlass 暗叠暗）

#### Scenario: 用户选择浅黄种子色

- **WHEN** 用户选取 luminance 高于阈值的浅色并保存（设置「彩色」自定义浅色）
- **THEN** `isDarkShell` 必须为 false
- **AND** `shellColor` / `surfaceColor` MUST 与经典同构为近白淡染（MUST NOT 将选中色满色设为 shell）
- **AND** `seedColor` MUST 为该选中色（染料）

#### Scenario: 夜空预设

- **WHEN** 用户选择夜空预设
- **THEN** shell/surface/accent MUST 使用夜空既定常量，MUST NOT 走自定义暗色 derive 覆盖

## ADDED Requirements

### Requirement: 浅色自定义与经典共用近白壳配方

Light custom seeds and classic light MUST resolve through the same near-white shell + seed dye recipe（shell ≈ white blended with seed at ~0.08 alpha; surface similarly lighter）. Legacy soft-swatch presets, when resolved, MUST use the same recipe. 浅色自定义 seed 与经典 MUST 共用近白壳 + seed 染料配方；遗留 soft swatch 解析时 MUST 用同一配方。

#### Scenario: 自定义浅蓝 shell 非满色

- **WHEN** 自定义浅色 seed 已保存且 `isDarkShell == false`
- **THEN** `shellColor` 的 luminance MUST 明显高于将该 seed 直接作 shell 时的满色页底
- **AND** MUST 与经典壳同属近白淡染结构

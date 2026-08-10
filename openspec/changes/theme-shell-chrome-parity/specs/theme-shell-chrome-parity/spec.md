## ADDED Requirements

### Requirement: 自定义浅色（设置「彩色」）与经典同构

When the user selects a custom light seed via settings「彩色」（`preset` null and seed luminance above the dark threshold）, the VisualBundle MUST use the same structural recipe as classic light: `seedColor` is the picked color（dye）; `shellColor` MUST be near-white tinted with that seed（e.g. white blended with seed at low alpha such as ~0.08）; `surfaceColor` MUST likewise be a lighter near-white tint—MUST NOT set `shellColor` equal to the full picked color. 当用户经设置「彩色」选择自定义浅色 seed（无 preset 且亮度高于暗色阈值）时，VisualBundle MUST 与经典浅色同构：`seedColor` 为选中色（染料）；`shellColor` MUST 为该 seed 淡染的近白（如白 + seed@~0.08）；`surfaceColor` MUST 同为更淡近白——MUST NOT 将 `shellColor` 设为选中色满色。

#### Scenario: 彩色选浅蓝后留意壳接近经典

- **WHEN** 用户在设置「彩色」中选取 luminance 高于暗色阈值的自定义色并保存
- **THEN** `isDarkShell` MUST 为 false
- **AND** `shellColor` MUST 为近白淡染（不得等于选中色满色铺底）
- **AND** 留意壳 MUST 呈现与经典同类的近白玻璃渐变（BackdropFilter 不得再灌满色页底）

#### Scenario: 经典仍为近白壳

- **WHEN** 用户选择经典
- **THEN** shell/surface/seed 结构 MUST 仍为近白壳 + 性别主色染料

### Requirement: 浅色 panelGlass 近白渐变

For any light shell, `panelGlassTop` / `panelGlassBottom` MUST use a near-white glass base tinted by `seedColor` with a lighter bottom stop so default `panelGlassGradient` shows a perceptible lightness delta, and MUST NOT bind the glass base to a full-saturation page shell. 任意浅壳下，`panelGlassTop`/`Bottom` MUST 用近白玻璃底 + `seedColor` 淡染且 bottom 更浅；MUST NOT 以满色页壳作玻璃底。

#### Scenario: 经典与自定义浅色 panelGlass 同构

- **WHEN** 用户分别使用经典与自定义浅色
- **THEN** 无 accent 的 `panelGlassGradient` MUST 均呈近白玻璃与可辨对角渐变

### Requirement: 暗壳 chrome 染料与夜空同构

For dark shells other than the fixed night-sky preset, the bundle MUST separate page shell/surface（derived from the dark input）from a brighter chrome accent used as `seedColor` for panelGlass blending, structurally matching night sky. Night-sky fixed hexes MUST remain unchanged. 除固定夜空外，其它暗壳 MUST 分离页底与偏亮 `seedColor` accent；夜空固定色值 MUST NOT 改。

#### Scenario: 自定义暗色留意壳接近夜空结构

- **WHEN** 用户保存 luminance 低于阈值的自定义暗色
- **THEN** shell/surface MUST 继承该暗色相
- **AND** chrome `seedColor` MUST 为相对页底偏亮的染料
- **AND** 留意壳 MUST 呈现深底+亮染层次

#### Scenario: 夜空预设不变

- **WHEN** 用户选择夜空预设
- **THEN** shell/surface/accent MUST 仍为既有夜空常量
- **AND** MUST NOT 被 deriveDark 覆盖

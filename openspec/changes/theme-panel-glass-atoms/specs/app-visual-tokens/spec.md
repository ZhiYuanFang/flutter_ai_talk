## ADDED Requirements

### Requirement: AppVisualTokens SHALL expose panelGlass paired roles

`AppVisualTokens` (or strictly equivalent fields read only via `AppColor`) SHALL expose paired panel-glass roles—at minimum top fill, bottom fill, and on-fill—derived in the single theme derivation entry (`VisualBundle.toTokens` or equivalent). On dark shells, top fill MUST NOT equal near-white content-card luminance strategy.

`AppVisualTokens`（或仅经 `AppColor` 暴露的等价字段）**必须** 提供 panelGlass 成对角色（至少 top、bottom、on）；由唯一派生入口计算。暗壳 top **不得** 采用近白 contentCard 亮度策略。

#### Scenario: 暗壳 panelGlass 与 contentCard 分离

- **WHEN** `isDarkShell == true` 且同时读取 contentCard 与 panelGlassTop
- **THEN** panelGlassTop 相对 shell/surface MUST 为主题色提亮暗浮层策略
- **AND** contentCard MAY 仍保持偏亮内容卡策略
- **AND** 二者 on* 前景 MUST 各自与底配对

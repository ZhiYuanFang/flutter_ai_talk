## MODIFIED Requirements

### Requirement: In-page chrome SHALL use panelGlass atoms

In-page glass chrome panels (prediction tip bar, care-alert shell, prediction event card chrome, **UCG square feed fake-glass / debate card shells**, and equivalent surfaces) SHALL resolve fill/gradient colors via `panelGlass*` semantic atoms / `AppColor.panelGlassGradient`, and MUST NOT assemble fills by blending high-luminance `contentCard` with hard-coded scheme accent alphas in business widgets.

页内玻璃 chrome（预测 tip、留意壳、预测事件卡外壳、**UCG 广场假玻璃与辩论卡外壳**等）**必须** 经 `panelGlass*` / `panelGlassGradient` 取色；业务 **不得** 再手拼近白 `contentCard` + 硬编码 accent alpha。

#### Scenario: 留意壳使用 panelGlass 渐变

- **WHEN** 智能预测页渲染「值得留意」玻璃壳
- **THEN** 背景渐变 MUST 来自 `AppColor.panelGlassGradient`（或等价 top/bottom 原子）
- **AND** MUST NOT 直接 `alphaBlend(scheme.tertiary, AppColor.contentCard)`

#### Scenario: tip 条同源角色

- **WHEN** 预测页渲染底部 tip 玻璃条
- **THEN** 填充/渐变角色 MUST 为 `panelGlass`（与留意壳同族）

#### Scenario: UCG 广场假玻璃同源角色

- **WHEN** UCG 广场渲染 Feed 假玻璃 panel 或辩论动态卡外壳
- **THEN** 填充/渐变角色 MUST 为 `panelGlass`（与预测 chrome 同族）
- **AND** MUST NOT 以 `contentCard` 作为暗壳卡底起笔

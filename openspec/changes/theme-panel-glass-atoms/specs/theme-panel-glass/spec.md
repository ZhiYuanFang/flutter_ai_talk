## ADDED Requirements

### Requirement: In-page chrome SHALL use panelGlass atoms

In-page glass chrome panels (prediction tip bar, care-alert shell, prediction event card chrome, and equivalent surfaces) SHALL resolve fill/gradient colors via `panelGlass*` semantic atoms / `AppColor.panelGlassGradient`, and MUST NOT assemble fills by blending high-luminance `contentCard` with hard-coded scheme accent alphas in business widgets.

页内玻璃 chrome（预测 tip、留意壳、预测事件卡外壳等）**必须** 经 `panelGlass*` / `panelGlassGradient` 取色；业务 **不得** 再手拼近白 `contentCard` + 硬编码 accent alpha。

#### Scenario: 留意壳使用 panelGlass 渐变

- **WHEN** 智能预测页渲染「值得留意」玻璃壳
- **THEN** 背景渐变 MUST 来自 `AppColor.panelGlassGradient`（或等价 top/bottom 原子）
- **AND** MUST NOT 直接 `alphaBlend(scheme.tertiary, AppColor.contentCard)`

#### Scenario: tip 条同源角色

- **WHEN** 预测页渲染底部 tip 玻璃条
- **THEN** 填充/渐变角色 MUST 为 `panelGlass`（与留意壳同族）

### Requirement: Dark-shell panelGlass MUST NOT start from near-white contentCard

When `isDarkShell` is true, `panelGlassTop` MUST be derived from `surface` (or shell) plus a restrained theme seed/primary lift, and MUST NOT use near-white `contentCard` / records (approx. L≥0.9) as the gradient base. Paired text MUST use `textOnPanelGlass` / `onPanelGlass` for readable contrast.

暗壳下 `panelGlassTop` **必须** 以 surface/shell + 克制主题色提亮派生，**不得** 以近白 contentCard 起笔；正文 **必须** 用 `textOnPanelGlass` 保证对比。

#### Scenario: 夜空下留意壳不发白

- **WHEN** 用户使用夜空主题查看预测页留意壳或 tip
- **THEN** 面板渐变起点 MUST 呈现略浅的主题色调而非大面积近白
- **AND** 标题/正文 MUST 与面板底形成可读对比

### Requirement: panelGlassGradient MAY accept event accent

`AppColor.panelGlassGradient` (or equivalent) SHALL accept an optional `accent` color. When null, theme primary/seed MUST drive the tint. When provided (e.g. event brand color), that accent MAY tint the gradient while alpha and base roles remain inside the atom implementation.

`panelGlassGradient` **必须** 支持可选 `accent`；为 null 时用主题强调色；非 null 时 MAY 用事件色着色，α 与底色角色仍由原子实现。

#### Scenario: 事件卡带事件色强调

- **WHEN** 预测事件卡传入事件品牌色作为 accent
- **THEN** 渐变 MUST 仍走 panelGlass 原子 API
- **AND** 强调叠色 MAY 使用该 accent（非业务侧再写一套 alphaBlend）

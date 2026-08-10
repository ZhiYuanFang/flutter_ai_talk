## ADDED Requirements

### Requirement: UCG feed and debate cards SHALL use panelGlass chrome

UCG square feed fake-glass panels and debate feed/share card shells SHALL resolve background gradients via `AppColor.panelGlassGradient` (or equivalent `panelGlass*` atoms) and MUST pair body/title text with `textOnPanelGlass` / muted variants. They MUST NOT use near-white `contentCard` as the dark-shell card base.

UCG 广场假玻璃与辩论 Feed/分享卡外壳 **必须** 经 `panelGlassGradient` / `panelGlass*` 取底，正文 **必须** 配对 `textOnPanelGlass`；暗壳 **不得** 以近白 `contentCard` 作卡底。

#### Scenario: 广场假玻璃挂 panelGlass

- **WHEN** 广场 Feed 渲染 `UcgFeedFakeGlassPanel`（含辩论动态卡）
- **THEN** 背景渐变 MUST 来自 `AppColor.panelGlassGradient`（可带可选 accent）
- **AND** 卡内主文案色 MUST 来自 `textOnPanelGlass`（或经其转发的 helper）
- **AND** MUST NOT 使用 `AppColor.contentCard` 作为暗壳卡底起笔

#### Scenario: 夜空下广场/辩论卡不发白

- **WHEN** 用户在夜空主题浏览 UCG 广场或辩论卡
- **THEN** 卡面 MUST 呈现主题色暗浮层观感（与预测 chrome 同族）
- **AND** 标题/正文 MUST 与卡底形成可读对比

### Requirement: Debate side category colors SHALL be semantic atoms

Left/right debate macaron gradients, label/percent colors, and VS chip fill/border/foreground SHALL be exposed as semantic atoms on `AppColor` / `AppVisualTokens` (or equivalent). Debate widgets MUST NOT hard-code category colors via `Color(0x…)` or `Colors.white` / `Colors.black` for those roles.

辩论左右侧渐变、标签/百分比字色、VS 中心钮填色/描边/前景 **必须** 经语义原子暴露；辩论 widget **不得** 对上述角色硬编码 `Color(0x…)` 或零散 `Colors.white` / `Colors.black`。

#### Scenario: VS 条取色经原子

- **WHEN** 渲染辩论 VS 条左右侧与中心钮
- **THEN** 渐变与字色 MUST 来自 `AppColor`（或转发原子的 helper）辩论侧角色
- **AND** `ucg_debate_vs_bar.dart` MUST NOT 内联马卡龙 `Color(0x…)` 常量作为填色源

#### Scenario: 左右侧仍可辨

- **WHEN** 经典或夜空主题下查看辩论卡
- **THEN** 左/右侧颜色角色 MUST 仍可区分（原子初值可对齐原品牌观感）

### Requirement: UCG business UI SHALL resolve colors via AppColor contract

UCG feature UI (shell text, panel text, dividers, card chrome) SHALL obtain colors through `AppColor` (or thin wrappers that only forward `AppColor` / tokens). Direct `Theme.extension<AppVisualTokens>()` field reads for those roles and ad-hoc hard-coded greys/whites for card chrome MUST NOT remain in migrated call sites. Immersive media scrims, if retained, MUST go through a single AppColor (or equivalent) atom entry rather than scattered literals.

UCG 业务 UI（壳字、面板字、分割线、卡 chrome）**必须** 经 `AppColor`（或仅转发的薄封装）取色；已迁移调用点 **不得** 再直读 tokens 字段或用零散白/灰硬编码卡 chrome。媒体沉浸遮罩若保留，**必须** 收口到单一原子入口。

#### Scenario: UcgTheme 不另起色源

- **WHEN** 代码经 `UcgTheme` 取壳上主文案色
- **THEN** 实现 MUST 转发 `AppColor.textPrimary`（或等价原子）
- **AND** MUST NOT 独立维护第二套色值表

#### Scenario: 假玻璃 helper 对齐 panelGlass

- **WHEN** 调用 `ucgFeedFakeGlassTextColor` / hint / secondary helpers
- **THEN** 返回色 MUST 派生自 `textOnPanelGlass` 族，而非 `textOnContentCard`

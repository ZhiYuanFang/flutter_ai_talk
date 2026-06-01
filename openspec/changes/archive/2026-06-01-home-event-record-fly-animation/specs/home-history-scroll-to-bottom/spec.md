## ADDED Requirements

### Requirement: 非底部时显示回到底部入口

The home history area MUST show a tappable control at the bottom center when the user has scrolled away from the latest records. 当用户**未**跟到底部（不在最新记录附近）且历史非空时，历史区**正下方**必须显示可点击控件，用于滚到最底部。

#### Scenario: 向上翻看后出现按钮

- **WHEN** 用户向上滚动历史列表且距底部超过跟底阈值
- **THEN** 历史区底部正中必须显示回到底部图标（或等价按钮）

#### Scenario: 已在底部隐藏

- **WHEN** 用户 scroll 位置已跟底
- **THEN** 回到底部控件必须隐藏

#### Scenario: 无历史隐藏

- **WHEN** 历史列表为空
- **THEN** 不得显示回到底部控件

### Requirement: 点击滚至最底部

The scroll-to-bottom control SHALL animate the history list to the maximum scroll extent. 点击回到底部控件时，历史列表 **必须** 滚动至最底部（最新 record）；**应该** 使用平滑滚动（如 `animateTo`）。

#### Scenario: 点击后到达底部

- **WHEN** 用户在非底部点击该控件
- **THEN** 列表必须滚至最底，且控件随后隐藏

#### Scenario: 与跟底状态一致

- **WHEN** 用户通过该控件滚到底
- **THEN** 内部跟底状态（如 `_followLatest`）必须更新为 true，以便后续新 record 自动滚底

### Requirement: 回到底部按钮视觉样式

The scroll-to-bottom control MUST be a circular floating button at the bottom center of the history area, with a downward-pointing triangle icon inside, themed from `ColorScheme.primary`. 回到底部控件 **必须** 为历史区正下方居中的 **悬浮正圆按钮**（非胶囊）；圆内 **必须** 居中显示 **向下三角形** 图标；颜色 **必须** 随当前主题主色变化，**不得** 硬编码固定色值。

#### Scenario: 圆形悬浮于历史区底缘正中

- **WHEN** 控件处于显示状态
- **THEN** 控件 **必须** 以正圆形容器呈现，悬浮于历史列表内容之上、历史区底部水平正中，距底约 8–12 logical px

#### Scenario: 主色 0.3 透明填充

- **WHEN** 用户切换主题预设、性别主色或自定义背景
- **THEN** 圆形 **填充色** **必须** 使用 `ColorScheme.primary` 且 alpha **必须为 0.3**（`primary.withValues(alpha: 0.3)` 或与 shell alphaBlend 后视觉等效）

#### Scenario: 更深主色描边

- **WHEN** 控件渲染描边
- **THEN** 圆环描边 **必须** 使用比 `primary` **更深** 的同色相色调（如对 primary 做 HSL 明度下调，或 `Color.alphaBlend(primary.withValues(alpha: ≥0.5), AppVisualTokens.pillBorder)`）；描边 **必须** 可见且与 0.3 填充形成对比

#### Scenario: 向下三角形图标

- **WHEN** 控件可见
- **THEN** 圆内 **必须** 显示向下指向的三角形/chevron 图标（如 `Icons.keyboard_arrow_down`），居中于圆形容器

#### Scenario: 主题 token 读取

- **WHEN** 实现读取颜色
- **THEN** 主色 **必须** 来自 `Theme.of(context).colorScheme.primary`；shell/边框辅助色 **应该** 通过 `AppVisualTokens`（`visualTokensOf(context)`）读取，与 `app/lib/theme/` 现有命名约定一致

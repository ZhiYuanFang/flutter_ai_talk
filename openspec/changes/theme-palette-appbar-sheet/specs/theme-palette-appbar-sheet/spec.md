## ADDED Requirements

### Requirement: 主壳三页顶栏最右调色盘入口

The feeding, smart-prediction, and UCG home-shell pages MUST show a theme-palette control as the rightmost action in their title/header bars. On the feeding page, the existing trends control MUST remain immediately to the left of the palette control. 喂养、智能预测与 UCG 主壳页 MUST 在标题/顶栏最右侧展示主题调色盘入口；喂养页既有趋势控件 MUST 紧邻其左侧保留。

#### Scenario: 喂养顶栏顺序

- **WHEN** 用户查看喂养页顶栏
- **THEN** 最右侧 MUST 为调色盘入口
- **AND** 趋势入口 MUST 在调色盘左侧

#### Scenario: 预测与 UCG 最右

- **WHEN** 用户查看预测页或 UCG 主壳可见顶栏
- **THEN** 调色盘入口 MUST 为该顶栏 actions 最右侧控件

### Requirement: 公用主题调色 Sheet

Tapping the palette control MUST open a single shared theme palette bottom sheet implementation（one module / one show helper reused by all three pages）. The sheet MUST support choosing classic, night sky, and custom（彩色）baselines, MUST show the custom color picker by default when custom selection is allowed, MUST include the auto night-sky toggle, and MUST persist via existing theme preference APIs. Pages MUST NOT duplicate separate sheet implementations. 点击调色盘 MUST 打开**唯一**共用的主题调色底部 Sheet；Sheet MUST 支持经典/夜空/彩色、在允许自定义时默认展示色盘、含自动夜空开关，并经既有主题持久化 API 写盘；各页 MUST NOT 各自复制 Sheet 实现。

#### Scenario: 三页打开同一套 Sheet

- **WHEN** 用户分别在喂养、预测、UCG 点击调色盘
- **THEN** 系统 MUST 展示同一公用 Sheet 实现（同一入口函数或等价共享组件）

#### Scenario: 改自定义色自动选中彩色

- **WHEN** 自动夜空关闭且用户在 Sheet 色盘中选择或变更自定义色
- **THEN** 「彩色」选中态 MUST 自动生效
- **AND** MUST 持久化该自定义 seed 为基线（preset 非夜空/非经典标记）

#### Scenario: 色盘默认展示

- **WHEN** 用户打开 Sheet 且当前允许自定义选色（自动夜空关闭）
- **THEN** 自定义色盘区域 MUST 默认可见（无需先点「彩色」才展开）

#### Scenario: 自动夜空开启时不可自定义选色

- **WHEN** 「自动夜空」为开启
- **THEN** Sheet MUST NOT 提供可用的自定义选色控件（可禁用或隐藏色盘交互）
- **AND** 自动夜空开关 MUST 仍可操作

### Requirement: 设置页不再承载主题区块

The settings screen MUST NOT display the theme preset swatches section or the settings-page「自动夜空」header row once the shared sheet is the entry point. Theme persistence and schedule behavior MUST remain available via the shared sheet. 设置页 MUST NOT 再展示主题预设 swatch 区与设置页内「自动夜空」标题行；主题持久化与调度 MUST 仍可通过公用 Sheet 使用。

#### Scenario: 设置无主题块

- **WHEN** 用户打开设置页
- **THEN** 界面 MUST NOT 再出现原「主题」预设选择与设置页内自动夜空行

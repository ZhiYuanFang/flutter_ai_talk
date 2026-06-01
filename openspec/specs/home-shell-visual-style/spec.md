## ADDED Requirements

### Requirement: 主页 Scaffold 使用 shell 令牌

The home screen Scaffold background MUST use `AppVisualTokens.shellColor` instead of relying solely on default scaffold or hardcoded colors. 主页 `Scaffold`（及同等最外层容器）背景必须使用 **`AppVisualTokens.shellColor`**，不得仅依赖未扩展的默认 scaffold 色或硬编码深色 hex。

#### Scenario: 切换至夜空后主页背景

- **WHEN** 用户启用夜空或深色 shell bundle 并进入主页
- **THEN** 主页最外层背景必须与 `tokens.shellColor` 一致，且与历史列表区域分层可见

### Requirement: 今日摘要药丸样式

The today summary panel SHALL render each total as a **pill-shaped chip** using `pillBackground` and `pillBorder` tokens, preserving fold/expand behavior and event branding colors. **今日摘要**每个总额 chip 必须为**药丸形**（Stadium 或等价），背景/描边来自 **`pillBackground` / `pillBorder`**；事件 logo 与 `resolveEventColor` 强调色必须保留；超过两行折叠/展开逻辑不得改变。

#### Scenario: 有今日数据且深色 shell

- **WHEN** 今日 `totals` 非空且 `isDarkShell` 为 true
- **THEN** chip 必须使用 pill 令牌渲染，且事件色用于图标/数值强调，不得退化为纯 `ColorScheme.primary` 扁平 Chip

#### Scenario: 折叠展开

- **WHEN** 摘要超过两行高度
- **THEN** 必须仍支持折叠与点击展开，行为与升级前一致

### Requirement: 历史按日卡片分层

History list day sections MUST be wrapped in a surface container (rounded corners, `surfaceColor`) distinct from the shell background. 历史列表按自然日分块必须置于 **`surfaceColor`** 圆角容器内（或与 design 一致的卡片层），与 shell 背景形成层次；日标题 [`HomeHistoryDateHeader`] 背景须使用 surface 语义而非仅 `themePrimaryBlend` 通栏浅色。

#### Scenario: 深色 shell 下日块

- **WHEN** 历史列表渲染某日记录块且 `isDarkShell` 为 true
- **THEN** 日块容器必须使用 `surfaceColor` 与 shell 对比可见，圆角半径须来自 tokens 或统一常量（12–16 logical px）

### Requirement: 时间轴 tile 尺寸与 logo 槽

Timeline tiles SHALL use token-aware row metrics and an enhanced EventLogo slot (padding/shadow) without changing tap, stop-timing, or WS-driven data. **时间轴行**必须使用与 tokens 一致的行高/字号区间（允许相对现网略增，如 36–38 logical px）；**EventLogo** 槽位必须有增强容器（内边距/轻阴影或描边）；点击进详情、计时停止、WS 更新逻辑**不得**改变。

#### Scenario: 最新一条强调

- **WHEN** 渲染 `fromBottom == 0` 的时间轴行
- **THEN** 时间轴圆点与字号强调规则必须与现网一致或略增强，且事件色仍来自 catalog

#### Scenario: 进行中计时停止按钮

- **WHEN** 行展示进行中计时且用户点击停止
- **THEN** 必须仍触发既有 stop 流程，不得因样式改动丢失按钮或回调

### Requirement: 按钮模式底部 elevated 面板

The button-mode event grid MUST sit on an elevated surface panel using `surfaceColor` and `panelShadow` tokens; cell layout and catalog split logic unchanged. **按钮模式**事件网格外层必须使用 **`surfaceColor` + `panelShadow`（或等价 elevation）** 的底部面板；两行横向滚动、目录对半分行、`EventLogo` + 名称 cell 结构**不得**改变；Phase 1 **不得**要求替换为 3D 图标资源。

#### Scenario: 切换到按钮模式

- **WHEN** 用户选择按钮输入模式且目录非空
- **THEN** 网格必须呈现在 elevated panel 之上，panel 与 shell 背景层次清晰

#### Scenario: 目录为空

- **WHEN** 按钮模式且目录为空
- **THEN** 必须仍展示空态文案，不得崩溃

### Requirement: 输入 dock 视觉与数据流隔离

The input mode dock SHALL align visually with the bottom panel tokens while preserving voice, text, and button mode switching and WS/history flows. **输入模式 dock**（语音/文字/按钮切换）必须与底部 panel 视觉统一（surface/shadow）；**不得**改动模式枚举、语音录制、文字发送、按钮 add 与历史 **WebSocket** 数据流。

#### Scenario: 三模式切换

- **WHEN** 用户在语音、文字、按钮间切换
- **THEN** 必须仍展示对应主输入 UI（语音球/文字框/事件网格），仅容器样式随 tokens 更新

#### Scenario: 历史 WS 推送新行

- **WHEN** 按钮或语音成功落库后 WS 推送新历史
- **THEN** 列表更新行为必须与升级前一致，不得依赖主题变更

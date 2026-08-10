## ADDED Requirements

### Requirement: Business UI colors SHALL use ColorScheme and AppVisualTokens

Business UI in `app/lib/ui/**` and `app/lib/ucg/**` SHALL resolve colors primarily from `Theme.of(context).colorScheme` and/or `Theme.extension<AppVisualTokens>()`, including shared theme helpers derived from those sources. Hard-coded brand or body text colors such as `Colors.black54`, fixed grey hex body colors, or `Colors.white` used as body text on light-tinted panels MUST NOT be introduced for ordinary chrome. Documented exceptions (event brand hex, media scrims, third-party SDK) MAY remain when commented.

业务 UI **必须** 优先使用 `colorScheme` 与 `AppVisualTokens`（及由其派生的 helper）；**不得** 用 `Colors.black54`、固定灰阶正文色或不当白字作为常规 chrome；事件品牌色/媒体遮罩/SDK 等例外须注释。

#### Scenario: 次要按钮前景随主题

- **WHEN** 宝宝绑定页在任意主题下展示「取消」
- **THEN** 取消按钮前景色 MUST 来自主题（如 `onShell`/`onSurface` 降透明度），MUST NOT 使用硬编码 `Colors.black54`

#### Scenario: 实心主按钮字色用 onPrimary

- **WHEN** 宝宝绑定页展示主确认 `FilledButton`
- **THEN** 按钮文字前景 MUST 使用 `colorScheme.onPrimary`（或等价主题强调前景），MUST NOT 写死与主题无关的 `Colors.white`（除非与 `onPrimary` 一致且经 theme 解析）

### Requirement: Dark shell glass fills MUST NOT be high-alpha white

When `AppVisualTokens.isDarkShell` is true, card/panel glass fills and borders used for feed cards, bind glass chrome, and prediction gate cards MUST NOT use large-area high-alpha white overlays that read as a bright white slab on the dark shell. Fills MUST instead blend `surface` / `recordsCardColor` / low-alpha `primary` (or equivalent helpers). Light shells MAY continue to use restrained white highlights.

暗壳下 Feed 卡/绑定玻璃/预测引导卡等玻璃底与边 **不得** 大面积高 alpha 白叠呈白板；**必须** 改用 surface/recordsCard/低 alpha primary 等主题叠色；浅壳 MAY 保留克制白高光。

#### Scenario: 夜空主题下动态卡片不呈白板

- **WHEN** 用户使用夜空或其它暗壳主题并打开 UCG 广场 Feed
- **THEN** 动态卡片背景 MUST NOT 呈现大面积突兀白底
- **AND** 卡片边框 MUST NOT 使用与浅色玻璃相同的高 alpha 纯白描边作为唯一方案

#### Scenario: 浅色主题下卡片仍可读

- **WHEN** 用户使用经典或自定义浅色主题打开 UCG Feed
- **THEN** 动态卡片 MUST 保持可读对比（允许适度白高光玻璃）

### Requirement: UCG primary list text SHALL follow shell foreground tokens

Primary and secondary text on the UCG square / feed main list SHALL use theme foreground tokens (`onShell`, `onRecordsCard`, or helpers such as `ucgFeedFakeGlassTextColor`) so that dark shells remain readable and do not rely on hard-coded light-theme greys.

UCG 广场/Feed 主列表主次文字 **必须** 使用 `onShell` / `onRecordsCard` 或等价 helper；暗壳下 **必须** 可读，**不得** 依赖浅色硬编码灰。

#### Scenario: 暗壳下 Feed 正文可读

- **WHEN** 暗壳主题下展示一条 Feed 动态正文
- **THEN** 正文颜色 MUST 来自主题前景 token
- **AND** MUST 与卡片/壳背景形成可读对比

### Requirement: Baby profile clay and prediction gate chrome SHALL track shell theme in P1

Baby profile clay surfaces and the smart-prediction login/bind gate card chrome in scope of this change SHALL derive panel/text/border colors from shell tokens or shared glass helpers so light and dark shells both remain coherent.

宝宝资料黏土面与预测登录/绑定引导卡 chrome **必须** 从 shell tokens 或共享玻璃 helper 取色，浅/暗壳均协调。

#### Scenario: 暗壳下引导卡不突兀白边白底

- **WHEN** 暗壳主题下展示预测页登录或绑定引导卡
- **THEN** 卡片边框与填充 MUST NOT 使用高 alpha 白底/白边导致突兀白板

#### Scenario: 暗壳下宝宝资料编辑面跟 shell

- **WHEN** 暗壳主题下打开宝宝资料编辑相关黏土面
- **THEN** 面板与主文字色 MUST 随 `shell`/`onShell`/`surface`（或等价推导）变化，MUST NOT 固定为浅色板常量而不考虑暗壳

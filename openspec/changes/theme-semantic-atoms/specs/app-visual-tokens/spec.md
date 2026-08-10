## ADDED Requirements

### Requirement: AppVisualTokens SHALL expose modal and content-card paired roles

`AppVisualTokens` SHALL include paired semantic fields (or strictly equivalent documented aliases) for content cards and modal overlays—at minimum fill and on-fill for content cards, and fill, border, and on-fill for modal overlays—derived in `VisualBundle.toTokens()` (or the single theme derivation entry) so consumers need not re-blend seed colors.

`AppVisualTokens` **必须** 提供 content 卡与 modal 浮层的成对语义字段（或文档等价别名）：至少 content 的 fill/on，modal 的 fill/border/on；由唯一主题派生入口计算，消费方 **不必** 自行再叠种子色。

#### Scenario: 暗壳 modal 与 content 亮度策略不同

- **WHEN** `isDarkShell == true` 且读取 tokens
- **THEN** `modalFill`（或等价）相对 shell/surface MUST 保持暗浮层可读策略
- **AND** `contentCard` / `recordsCardColor` MAY 保持偏亮内容卡策略
- **AND** 各自 `on*` 前景 MUST 与对应底配对（经 luminance 兜底）

#### Scenario: ThemeExtension 仍可 copyWith/lerp

- **WHEN** 框架对含新字段的 `AppVisualTokens` 做 `copyWith` 或 `lerp`
- **THEN** MUST NOT 抛出未实现错误，新字段 MUST 参与复制/插值（或与文档约定的别名字段一致）

## MODIFIED Requirements

### Requirement: AppVisualTokens ThemeExtension

The app SHALL expose an `AppVisualTokens` `ThemeExtension` on `ThemeData.extensions` with semantic colors and elevation for shell, surface, pill, panel, content-card, and modal layers. 应用必须在 `ThemeData.extensions` 上提供 **`AppVisualTokens`**，包含 shell、surface、pill、panel、content 卡、modal 浮层及阴影/描边等语义字段；主页、设置、Dialog/软引导与 Feed 相关 UI 必须优先读取该扩展或经其封装的原子 API，不得在新代码中硬编码 `#1A1C24` 作为唯一深色背景，也不得用单一 glass 叠色同时充当浅内容卡与暗 Dialog 底。

#### Scenario: 读取令牌

- **WHEN** 任意 widget 调用 `Theme.of(context).extension<AppVisualTokens>()`
- **THEN** 必须得到非 null 的令牌实例，且 `shellColor`、`surfaceColor`、`isDarkShell` 与当前主题 bundle 一致

#### Scenario: ThemeExtension 完整性

- **WHEN** Flutter 框架对主题做 `lerp` 或 `copyWith`
- **THEN** `AppVisualTokens` 必须实现 `copyWith` 与 `lerp`，不得抛出未实现错误

#### Scenario: 业务优先原子入口

- **WHEN** 业务代码需要页面底或通用正文色
- **THEN** SHOULD 经语义原子 API 读取，其结果 MUST 与 tokens 中对应字段一致

### Requirement: 文本对比度兜底

The system SHALL ensure primary labels on shell, surface, content-card, and modal layers meet readable contrast by adjusting the paired `on*` / `textOn*` colors when derived colors are too close in luminance. 系统必须对 shell、surface、content 卡、modal 上的主文本提供配对前景；当推导色对比不足时，必须回退为高可读性的浅/深前景色，不得出现不可读的同色文字（包括暗壳下浅 modal 底配白字的错误配对——此时应修正底色角色或前景角色，而非仅降低 alpha）。

#### Scenario: 深 shell 上的标题

- **WHEN** `isDarkShell` 为 true 且渲染主页 AppBar 或日标题
- **THEN** 前景色必须与 `shellColor` 或 `surfaceColor` 形成可读对比（实现可采用 luminance 阈值）

#### Scenario: 暗壳 modal 上的标题

- **WHEN** `isDarkShell` 为 true 且渲染 modal 浮层标题
- **THEN** 前景 MUST 与 `modalFill` 形成可读对比
- **AND** MUST NOT 使用仅适用于深 shell 的白字压在浅 contentCard 底上

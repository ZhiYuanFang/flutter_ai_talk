## ADDED Requirements

### Requirement: AppVisualTokens ThemeExtension

The app SHALL expose an `AppVisualTokens` `ThemeExtension` on `ThemeData.extensions` with semantic colors and elevation for shell, surface, pill, and panel layers. 应用必须在 `ThemeData.extensions` 上提供 **`AppVisualTokens`**，包含 shell（外壳）、surface（卡片/面板）、pill（药丸 chip）、panel（底部输入区）及阴影/描边等语义字段；主页与设置相关 UI 必须优先读取该扩展，不得在新代码中硬编码 `#1A1C24` 作为唯一深色背景。

#### Scenario: 读取令牌

- **WHEN** 任意 widget 调用 `Theme.of(context).extension<AppVisualTokens>()`
- **THEN** 必须得到非 null 的令牌实例，且 `shellColor`、`surfaceColor`、`isDarkShell` 与当前主题 bundle 一致

#### Scenario: ThemeExtension 完整性

- **WHEN** Flutter 框架对主题做 `lerp` 或 `copyWith`
- **THEN** `AppVisualTokens` 必须实现 `copyWith` 与 `lerp`，不得抛出未实现错误

### Requirement: 经典浅色默认 bundle

The system SHALL use a **classic light** visual bundle as the default when no custom background or preset is persisted. 当本地无自定义背景且无主题预设时，系统必须使用**经典浅色** bundle：`isDarkShell == false`，`shellColor` 与现有「性别 primary @ 8% blend 白底」行为一致，且不得默认启用深色 shell。

#### Scenario: 首次安装

- **WHEN** 用户从未保存自定义背景或预设
- **THEN** `AppVisualTokens.isDarkShell` 必须为 false，主页观感与升级前默认浅色一致

#### Scenario: 清除自定义

- **WHEN** 用户在设置中执行「清除自定义背景/恢复默认」
- **THEN** 必须回到 classic light bundle，并清除 preset 标记

### Requirement: 深色 shell HSL 推导

When the user seed color has sufficiently low luminance or maps to the night preset, the system MUST derive `shellColor` and `surfaceColor` from the seed via HSL adjustment rather than using a single fixed hex for all users. 当用户种子色亮度低于产品阈值（或选用深色预设）时，系统必须基于种子色 **HSL** 推导 `shellColor` 与 `surfaceColor`（surface 相对 shell 略提亮），**不得**对所有用户写死同一 shell 色值；「夜空」预设除外（见 `theme-settings-presets`）。

#### Scenario: 用户选择深紫种子色

- **WHEN** 用户从颜色选择器选取 luminance 低于阈值的自定义色并保存
- **THEN** `isDarkShell` 必须为 true，且 `shellColor` 的色相/饱和度须继承该种子色（亮度钳制在 shell 区间）

#### Scenario: 用户选择浅黄种子色

- **WHEN** 用户选取 luminance 高于阈值的浅色并保存
- **THEN** `isDarkShell` 必须为 false，shell 行为与浅色 bundle 一致

### Requirement: buildAppTheme 挂载令牌与 ColorScheme 分支

`buildAppTheme` MUST attach `AppVisualTokens` and SHALL build `ColorScheme` with `Brightness.dark` when `isDarkShell` is true, otherwise light with sex-based primary. **`buildAppTheme`** 必须根据 bundle 挂载 `AppVisualTokens`；`isDarkShell == true` 时 `ColorScheme` 必须为 **dark** 分支（seed 为用户种子或预设 seed），否则为 **light** 且 primary 仍由宝宝性别决定。

#### Scenario: 深色 shell 下 ColorScheme

- **WHEN** `AppVisualTokens.isDarkShell` 为 true
- **THEN** `ThemeData.colorScheme.brightness` 必须为 `Brightness.dark`，且 `scaffoldBackgroundColor` 必须等于 `tokens.shellColor`

#### Scenario: 浅色模式下性别 accent

- **WHEN** `AppVisualTokens.isDarkShell` 为 false
- **THEN** `ColorScheme.primary` 必须仍由 `BabySex` 映射（男/女/未知），与现有逻辑一致

### Requirement: 文本对比度兜底

The system SHALL ensure primary labels on shell and surface layers meet readable contrast by adjusting `onShell` / `onSurface` when derived colors are too close in luminance. 系统必须对 shell/surface 上的主文本提供 **`onShell` / `onSurface`**（或等价语义）；当推导色对比不足时，必须回退为高可读性的浅/深前景色，不得出现不可读的同色文字。

#### Scenario: 深 shell 上的标题

- **WHEN** `isDarkShell` 为 true 且渲染主页 AppBar 或日标题
- **THEN** 前景色必须与 `shellColor` 或 `surfaceColor` 形成可读对比（实现可采用 luminance 阈值）

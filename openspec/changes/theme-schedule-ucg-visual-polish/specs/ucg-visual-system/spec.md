## ADDED Requirements

### Requirement: UCG light-surface text SHALL use readable foreground on recordsCardColor

When UCG inline surfaces use `recordsCardColor`, light glass fills, or equivalent high-luminance backgrounds, foreground text and icons MUST use `AppVisualTokens.onRecordsCard` (or a color derived from `_readableOn` of that surface fill). UCG MUST NOT use `onShell` for body text on such light surfaces when `isDarkShell` is true.

UCG 在浅色 records 卡或 light glass 背景上 MUST 使用 `onRecordsCard` 等可读前景色，暗色 shell 下不得白底配 `onShell` 白字。

#### Scenario: 夜空下广场卡片可读
- **WHEN** 用户生效主题为夜空且浏览 UCG 广场 Feed 卡片
- **THEN** 卡片内标题与元信息文字 SHALL 与卡片背景对比度可读（深色字 on 浅色卡）

#### Scenario: 夜空下发布页 light glass 可读
- **WHEN** 用户在夜空主题下打开发布页 `UcgComposeLightGlassPanel` 区域
- **THEN** 正文、占位 hint 与次要文案 SHALL 使用相对 panel 填充色可读的前景色

#### Scenario: 深色 shell 下列表行浅底可读
- **WHEN** `UcgSurfaceCard` 使用 `recordsCardColor` 填充且 `isDarkShell` 为 true
- **THEN** 卡片内文字 SHALL 使用 `onRecordsCard` 而非 `onShell`

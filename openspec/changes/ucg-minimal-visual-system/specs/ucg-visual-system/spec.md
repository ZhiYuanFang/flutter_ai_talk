## MODIFIED Requirements

### Requirement: UCG UI SHALL reuse feeding-module theme tokens

All UCG screens MUST inherit the app-wide theme from `AppThemeScope` and read colors via `AppVisualTokens` and `Theme.of(context).colorScheme` (especially `primary`). UCG MUST NOT introduce a separate color palette or hardcoded brand colors outside existing theme helpers (`themePrimaryBlend`, `visualTokensOf`).

UCG 必须继承全 App 主题 token；强调色与 shell 背景解析结果与喂养页一致，但 UCG 允许采用与喂养不同的**简约**表面风格（见下文），不得引入独立色板。

#### Scenario: 切换主题预设后 UCG 同步变色
- **WHEN** 用户在设置中切换宝宝主题/背景预设
- **THEN** UCG 壳、广场、消息、我的页的 shell 背景、强调色与选中态 SHALL 与喂养页使用同一套 token 解析结果

#### Scenario: 强调交互使用主题色
- **WHEN** 用户查看底部导航选中项、点赞态、链接或未读红点
- **THEN** UI SHALL 使用 `ColorScheme.primary` 或其 `withValues(alpha: …)` 变体，而非固定 hex

### Requirement: UCG layout SHALL be immersive without separated top tab chrome

UCG pages MUST NOT use a visually separated top TabBar or AppBar color block that splits header from content (different background colors or elevation seam). Page root SHALL use `Scaffold(backgroundColor: shellColor)` with continuous background. Sub-tabs (e.g. 广场 关注/推荐) SHALL be inline segmented controls embedded in the content column below an immersive header (pattern: `HomeImmersiveHeader`), sharing the same `shellColor` as the list below.

#### Scenario: 广场关注/推荐无头身分离
- **WHEN** 用户打开广场 Tab
- **THEN** 关注/推荐切换控件 SHALL 内嵌于顶栏行（轻量文字选中：颜色+字重），且 SHALL NOT 渲染为独立 Material `TabBar` 条叠在 contrasting 背景上

#### Scenario: 无独立 AppBar 色块
- **WHEN** 用户浏览 UCG 任意 Tab 根页面
- **THEN** UI SHALL NOT 显示与 `shellColor` 不一致的 `AppBar` 背景色块；顶栏标题/返回 SHALL 采用沉浸式布局（透明/同 shell 背景）

## REMOVED Requirements

### Requirement: UCG surfaces SHALL use glass morphism consistent with feeding module

**Reason**: UCG 视觉体系 pivot 为简约风；内联 UI 不再强制喂养同款玻璃拟态。喂养模块仍保留玻璃组件，UCG 与之风格分叉但共享 token。

**Migration**: 使用 `UcgSurfaceCard` 轻表面、`UcgBottomDock` / `UcgInputDock` 扁平条；UCG 内联区域禁止 `BackdropFilter` 磨砂容器。UCG 模态 Sheet 使用 flat sheet，不再强制 `showGlassAdaptiveBottomSheet`（详情氛围 blur 除外，见 `ucg-square-feed` / 详情实现）。

### Requirement: UCG bottom navigation SHALL use glass dock styling

**Reason**: 底部五栏改为全宽扁平嵌入 `shellColor`，见 `ucg-shell-navigation` 新条款。

**Migration**: `UcgGlassBottomDock` 改为 `UcgBottomDock` 扁平实现；删除 pill blur、渐变、阴影。

## ADDED Requirements

### Requirement: UCG inline surfaces SHALL use minimal light-surface styling

UCG inline cards, list rows, input docks, and bottom navigation MUST use minimal styling: continuous `shellColor` background, optional light-surface fill (`recordsCardColor` or low-alpha `themePrimaryBlend`), `surfaceRadius` corners, and NO `BackdropFilter` blur, NO gradient glass fill, NO luminous border, and NO `panelShadow` on inline chrome.

UCG 内联卡片、列表行、输入条与底栏必须采用简约轻表面风格，不得使用磨砂玻璃、渐变描边或悬浮阴影 pill。

#### Scenario: Feed 卡片轻表面
- **WHEN** 广场双列 Feed 展示帖子卡片
- **THEN** 卡片容器 SHALL 为轻表面（无 blur），详见 `ucg-square-feed`

#### Scenario: 内联 UI 禁止玻璃磨砂
- **WHEN** 用户浏览 UCG 消息列表、我的资料区或发布页表单分区
- **THEN** 容器 SHALL NOT 使用 `BackdropFilter` 或喂养 `HistoryEditGlassPanel` 风格包裹内联内容

### Requirement: UCG selection states SHALL use lightweight color and weight only

Selected tabs, segmented controls, and bottom navigation items MUST indicate selection via `ColorScheme.primary` and font weight only. They MUST NOT render background pill fills (e.g. `primary.withValues(alpha: 0.12)` rounded boxes) on selected inline nav items.

选中态必须仅通过主题色与字重区分，不得使用圆角底色 pill 块（底栏、顶栏 segmented 均适用）。

#### Scenario: 底栏选中无底色块
- **WHEN** 用户选中底部「广场」或「我的」
- **THEN** 图标与标签 SHALL 使用 primary 色与较重字重，且 SHALL NOT 显示选中底色圆角块

#### Scenario: 广场推荐关注轻量选中
- **WHEN** 用户在广场切换推荐/关注
- **THEN** 选中项 SHALL 仅以 primary 色与字重区分，无独立背景盒

### Requirement: UCG scaffolds SHALL not resize for keyboard inset by default

UCG page scaffolds (`UcgScaffold` and equivalent) MUST default to `resizeToAvoidBottomInset: false` so primary content does not jump when the keyboard opens; text input SHALL be managed via `keyboard-top-input-confirm-bar`.

UCG 页面 Scaffold 默认不得因键盘 inset 顶起主体内容；输入体验由键盘顶部确认条承接。

#### Scenario: 键盘弹出布局稳定
- **WHEN** 用户在 UCG 页面聚焦受管控输入框
- **THEN** 主体内容区域 SHALL 保持位置稳定，键盘顶部 SHALL 显示确认条

### Requirement: UCG post detail MAY retain atmospheric backdrop blur

The immersive post detail screen MAY keep a full-screen atmospheric `BackdropFilter` blur on the hero image or cover for depth. This exception MUST NOT be applied to inline cards, bottom bars, or input docks.

帖子详情页允许保留全屏氛围模糊背景；该例外不得延伸至 Feed 卡片、底栏或输入条。

#### Scenario: 详情氛围 blur 保留
- **WHEN** 用户打开帖子详情且存在封面图
- **THEN** 背景层 MAY 使用 `BackdropFilter` 模糊，内容区仍无圆角玻璃卡包裹

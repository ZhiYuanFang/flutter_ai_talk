## ADDED Requirements

### Requirement: UCG UI SHALL reuse feeding-module theme tokens

All UCG screens MUST inherit the app-wide theme from `AppThemeScope` and read colors via `AppVisualTokens` and `Theme.of(context).colorScheme` (especially `primary`). UCG MUST NOT introduce a separate color palette or hardcoded brand colors outside existing theme helpers (`themePrimaryBlend`, `visualTokensOf`).

#### Scenario: 切换主题预设后 UCG 同步变色
- **WHEN** 用户在设置中切换宝宝主题/背景预设
- **THEN** UCG 壳、广场、消息、我的页的 shell 背景、强调色与选中态 SHALL 与喂养页使用同一套 token 解析结果

#### Scenario: 强调交互使用主题色
- **WHEN** 用户查看底部导航选中项、点赞态、链接或未读红点
- **THEN** UI SHALL 使用 `ColorScheme.primary` 或其 `withValues(alpha: …)` 变体，而非固定 hex

### Requirement: UCG surfaces SHALL use glass morphism consistent with feeding module

Cards, bottom sheets, dialogs, and floating chrome in UCG MUST reuse existing glass components: `HistoryEditGlassPanel`, `showGlassAdaptiveBottomSheet`, and `showGlassDialog` from `app/lib/ui/widgets/app_glass_overlay.dart`. New UCG-specific panels MUST follow the same blur, gradient, border, and radius conventions (`surfaceRadius`, ~22px sheet radius).

#### Scenario: 弹层使用玻璃 Sheet
- **WHEN** UCG 需要展示确认框、筛选或半屏操作（如评论输入）
- **THEN** App SHALL 使用 `showGlassAdaptiveBottomSheet` / `showGlassDialog`，且 SHALL NOT 使用默认不透明 Material bottom sheet

#### Scenario: Feed 卡片玻璃/表面风格
- **WHEN** 广场展示动态卡片
- **THEN** 卡片容器 SHALL 使用 `AppVisualTokens` 表面语义（如 `recordsCardColor` 或 `themePrimaryBlend` 浅色底）及圆角 `surfaceRadius`，与喂养历史卡片视觉层级一致

### Requirement: UCG layout SHALL be immersive without separated top tab chrome

UCG pages MUST NOT use a visually separated top TabBar or AppBar color block that splits header from content (different background colors or elevation seam). Page root SHALL use `Scaffold(backgroundColor: shellColor)` with continuous background. Sub-tabs (e.g. 广场 关注/推荐) SHALL be inline segmented controls embedded in the content column below an immersive header (pattern: `HomeImmersiveHeader`), sharing the same `shellColor` as the list below.

#### Scenario: 广场关注/推荐无头身分离
- **WHEN** 用户打开广场 Tab
- **THEN** 关注/推荐切换控件 SHALL 内嵌于内容区（pill/segmented），且 SHALL NOT 渲染为独立 Material `TabBar` 条叠在 contrasting 背景上

#### Scenario: 无独立 AppBar 色块
- **WHEN** 用户浏览 UCG 任意 Tab 根页面
- **THEN** UI SHALL NOT 显示与 `shellColor` 不一致的 `AppBar` 背景色块；顶栏标题/返回 SHALL 采用沉浸式布局（透明/同 shell 背景）

### Requirement: UCG bottom navigation SHALL use glass dock styling

The five-item UCG bottom bar MUST NOT use the default elevated `BottomNavigationBar` solid bar. It SHALL render as a floating glass dock (blur + semi-transparent surface + rounded pill) anchored above the safe area, with selected item highlighted by `ColorScheme.primary`.

#### Scenario: 底部栏与背景融合
- **WHEN** 用户查看 UCG 壳任意 Tab
- **THEN** 底部五栏 SHALL 为玻璃拟态悬浮 dock，且 SHALL NOT 呈现与 shell 背景明显分层的纯色底栏

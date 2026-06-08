## ADDED Requirements

### Requirement: Square feed masonry cards SHALL use light-surface containers

Masonry feed cards on 广场 SHALL wrap content in a light-surface container (`UcgSurfaceCard` or equivalent): solid low-contrast fill from `AppVisualTokens`, `surfaceRadius` (~12 logical px), padding ~10, and NO `BackdropFilter`, NO gradient glass, NO panel shadow.

广场双列 Feed 卡片必须使用轻表面容器包裹，不得使用 `UcgShellGlassCard` 玻璃拟态。

#### Scenario: 双列卡片轻表面
- **WHEN** 用户在广场推荐或关注 Feed 浏览帖子
- **THEN** 每张 masonry 卡片 SHALL 展示为轻表面矩形（可读边界），且 SHALL NOT 使用磨砂 blur 或渐变描边阴影

#### Scenario: 卡片交互不变
- **WHEN** 用户与 Feed 卡片交互（点心形、点图 lightbox、点空白进详情）
- **THEN** 行为 SHALL 与 `ucg-square-detail-notifications-redesign` 交互矩阵一致，仅容器视觉改为轻表面

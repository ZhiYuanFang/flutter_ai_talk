## Context

紧凑态现为 `GridView` + 固定 `childAspectRatio`，卡片标题行含小 `EventLogo`，主区为大号倒计时。默认布局与本地记忆已由 `PredictionLayoutStore`（缺省 grid）提供。

## Goals / Non-Goals

**Goals:**

- 紧凑态双列瀑布流（高度随内容）。
- 大图居中在倒计时上方；标题行无小 logo。
- 未超时、推演开、可预测中 `nextAt` 最早者大图持续心跳。

**Non-Goals:**

- 不改列表折线卡结构、倒计时/超时文案规则、推演开关语义。
- 不强制重置用户已存 `list` 偏好。
- 不新建测试文件。

## Decisions

1. **瀑布流实现优先无新依赖**  
   双列交错：`CustomScrollView` + 两列 `Column` 按 index 奇偶分发，或等价自写 masonry；卡片用固有高度（去掉 `Expanded` 倒计时槽，改为固定/内容高度）。  
   **备选**：`flutter_staggered_grid_view`——仅当自写成本过高再引入。

2. **持久化键仍用 `grid`**  
   UI 文案/图标可称「瀑布流」；存储值不改，避免迁移。

3. **心跳目标**  
   `forecastEnabled && prediction != null && !isOverdue(now)` 中 `nextAt` 最小；并列取稳定次序（如列表先出现者）。`ScaleTransition` 循环（约 0.9↔1.05，~800ms，`repeat(reverse: true)`）。

4. **卡片结构（compact）**  
   `[名 | 开关]` → `[大 Logo ~48–56]` → `[倒计时]`；超时短文案仍在名下（若有）。

## Risks / Trade-offs

- [双列分发滚动同步] → 用单一滚动视口包两列，避免两独立 ListView。  
- [多卡同时 AnimationController] → 仅心跳卡挂控制器，其余无动画。

## Migration Plan

- 热重载即可；已存 `grid` 用户直接看到瀑布流。

## Open Questions

- （无）已按产品倾向：心跳不含超时；标题行无小 logo。

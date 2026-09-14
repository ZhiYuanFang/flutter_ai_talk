## Context

`FeedingAnalysisScreen` 仍用 Hub 同款玻璃卡包住标题/CTA/blurb/列表；`GrowthTrajectoryScreen` 已是无卡页：渐变底、透明 AppBar、CTA 与用量小字在 `actions`。用户选定方案 B，并把「每日仅支持分析一次」对齐成长用量挂点。

## Goals / Non-Goals

**Goals:**

- 喂养工作台视觉壳与成长同构（无卡、渐变、AppBar CTA）
- 「每日一次」仅在工作台侧改挂到 AppBar CTA 下（Hub 卡上展示保留）
- 保留 `feature-accent-text-parity` 字色：AppBar 标题/CTA/blurb/muted 跟 care-alert accent

**Non-Goals:**

- 不改 Hub 喂养入口卡结构或模拟样张
- 不改 daily / 开通 / 资格门闸业务
- 不给结果列表加回卡片壳
- 不改成长页

## Decisions

1. **壳**：照抄成长：`bgStart = AppColor.pageBg`，`bgEnd = Color.lerp(bgStart, accent, ~0.28)`；`extendBodyBehindAppBar` + 透明 AppBar；`SafeArea` + `ListView(blurb, body)`。
2. **CTA**：抽取与 `_GrowthAppBarCta` 同构的小部件（可内联 `_FeedingAppBarCta`）：主钮「AI智能分析」+ 下方「每日仅支持分析一次」。显示条件与现逻辑一致：`elig.isQualified && unlocked && !loading`。
3. **每日一次可见性**：仅当 AppBar CTA 可见时展示该小字（与成长 usage 仅在 CTA 旁出现一致）。Hub 侧「每日一次」Requirement 不变。
4. **列表**：扁平 `ListTile` + `Divider`；字色可继续用可读色（accent 加深或 onShell），不加玻璃面板。
5. **双标题**：去掉卡内 logo+标题行；AppBar 保留 logo+「喂养记录分析」（accent）。

## Risks / Trade-offs

- [列表在渐变上偏空] → 保留分割线；验收若显飘可再加极轻底（本 change 不加壳）
- [toolbar 高度] → CTA+小字时抬高 `toolbarHeight`（对齐成长 64）
- [与 accent-parity「in-card」措辞] → 本 change 规格按页级 chrome 表述；字色仍跟 accent

## Migration Plan

纯 UI；回滚即恢复玻璃卡 + 卡内 CTA。

## Open Questions

无（B + 每日一次挂点已拍板）。

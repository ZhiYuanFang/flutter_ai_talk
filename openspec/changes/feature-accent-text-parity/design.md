## Context

AI 分析 Hub（`ai_analysis_screen.dart` / `_HubGlassCard`）已将标题、时效、body、模拟样张字色统一为 `resolveFeatureColor`（可加深）。开通中心（`feature_unlock_hub_screen.dart`）在 `feature-unlock-dialog-brand-accent` 下刻意保持标题/介绍为 `onShell`；喂养工作台（`feeding_analysis_screen.dart`）标题与 muted 用 `onGlass` / 降透；成长工作台（`growth_trajectory_screen.dart`）全文偏 `onShell`。用户选定方案 A：只对齐字色，不动玻璃壳与页结构。

## Goals / Non-Goals

**Goals:**

- 开通中心功能卡标题与介绍跟行 accent
- 喂养 / 成长工作台页内主文案（标题、介绍 blurb、muted 提示、开通引导、成长会话提示等）跟对应功能 accent
- 浅底上的正文用加深 accent（对齐 Hub `_deepenAccent` 思路），避免高透明发灰
- 规格推翻开通中心「标题不得跟色」

**Non-Goals:**

- 不改 `SettingsGlassPanel` 配方，不强制开通卡改用 `panelGlassGradient`
- 不把成长页改成 Hub 式单玻璃卡；不改整页 `pageBg` lerp 结构
- 不在详情页加「模拟内容」角标或替换为 Hub 模拟样张文案
- 不改 CTA 交互、路由、开通业务、SSE / daily 行为

## Decisions

1. **字色源**：一律 `resolveFeatureColor(context, catalogItem)`；缺项回退主题 primary（既有）。
2. **加深策略**：压在浅底（介绍 blurb / fieldFill 类）上的正文用 `Color.lerp(accent, black, ~0.18)` 或与 Hub 同等加深；标题与壳上主文案可用全色 accent；次文案可 `accent.withValues(alpha: 0.65~0.85)`。
3. **开通中心范围**：catalog **每一行**标题与介绍跟各自 accent（与 CTA 已跟色范围一致）；不单限 care / growth。
4. **成长页 AppBar**：标题「成长轨迹」跟 accent；壳背景透明 / 渐变不变。用量小字与 CTA 跟色程度与页内一致（accent 或加深），不改布局。
5. **与 brand-accent 关系**：本 change 规格 **MODIFIED**「标题不得跟色」为「标题与介绍必须跟色」；实现时以本 change 为准。

## Risks / Trade-offs

- [开通卡标题过彩抢 CTA] → 介绍用降透 accent；标题 w700 全色即可，CTA 仍描边 accent 可辨
- [暗色主题加深过黑] → 加深系数与 Hub 一致；暗壳下可仅用全色 accent（实现时按壳亮度二选一，验收以可读为准）
- [与未归档 brand-accent 双写冲突] → tasks 明确：改 `feature_unlock_hub_screen` 标题色时以本规格为准；归档时后写覆盖

## Migration Plan

纯客户端 UI；无数据迁移。回滚即恢复 `onShell` / `onGlass` 字色。

## Open Questions

无（方案 A 已拍板）。

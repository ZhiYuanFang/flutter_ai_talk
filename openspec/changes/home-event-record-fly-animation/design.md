## Context

- WS 推送 → `upsertRecord`；`HomeHistoryScroll` 当前在任意新 record 时 **总是** `scrollToBottom`。
- 已有 `_followLatest` 概念（距底 ≤96px 视为在底部），用于智能跟底。
- 原策略 A（非底部也滚底）已 **废止**；改为策略 **B+**。

## Goals / Non-Goals

**Goals:**

- WS 新增 record 时飞行动画反馈。
- 非底部：**不抢滚动位置**，动画仍指向底部新 record。
- 非底部：提供 **回到底部** 图标。
- 在底部：滚底 + 飞入锚点（与现网一致）。

**Non-Goals:**

- update/delete 动画；Rive/Lottie；改 WS 协议（MVP）。

## Decisions

### 1. 触发（不变）

`watchLatest` 中 upsert 前 `!items.any((e) => e.id == r.id)` → scheduleFly。

### 2. 跟底分支（策略 B+）

| 状态 | 新 record 时列表 | 飞行动画终点 |
|------|------------------|--------------|
| `_followLatest == true` | `scrollToBottom()` | 锚点 logo 实测 global 中心 |
| `_followLatest == false` | **不** `scrollToBottom` | 仍测锚点；若 `anchor.dy > historyBottom`，可见落点为 **历史区底缘中心**（用户看见飞向底部）；动画结束后列表 logo 正常存在（屏外） |

**理由**：不打断阅读；动画仍表达「新记录落到底部」。

### 3. 回到底部按钮

- **显示**：`_followLatest == false` 且历史非空。
- **位置**：历史 `Expanded` 区域 **底部正中**，浮于列表之上（`Stack`），距底 ~8–12px；不得遮挡底部输入区。
- **形状**：**正圆**（`BoxShape.circle`），建议直径 40–44 logical px；**禁止**胶囊/Stadium 形态。
- **图标**：圆内居中 **向下三角形**（`Icons.keyboard_arrow_down` 或等价 chevron/三角 Icon）；图标色与主色一致或略深，保证在 0.3 透明填充上可读。
- **主题色源**：`Theme.of(context).colorScheme.primary`（与 `AppThemeScope.buildAppTheme` / 性别主色、`ThemePreset` 预设一致）；实现时通过 `Theme.of(context)` 读取，**不得**硬编码 swatch。
- **填充**：`primary.withValues(alpha: 0.3)`；若需与 shell 底融合，可用 `Color.alphaBlend(primary.withValues(alpha: 0.3), tokens.shellColor)`，但视觉透明度 **必须** 等价于主色 0.3。
- **描边（更深主色）**：圆环 1–1.5 logical px。优先 `_darkenPrimary(primary, tokens.isDarkShell)`：对 `primary` 做 HSL 明度下调（浅色 shell：`-0.12`；深色 shell：`-0.08`），与 `theme_preset.dart` 中 `_adjustLightness` 同思路。备选（与 `home_today_summary_panel` pill 一致）：`Color.alphaBlend(primary.withValues(alpha: 0.55), tokens.pillBorder)`。
- **阴影**：可选 `tokens.panelShadow` 或 `primary.withValues(alpha: 0.18)` 轻阴影，不压过描边对比。
- **读取 token**：`visualTokensOf(context)` / `Theme.of(context).extension<AppVisualTokens>()` 取 `shellColor`、`isDarkShell`、`pillBorder`；主色始终来自 `colorScheme.primary`。
- **点击**：`scrollToBottom(animate: true)` 并置 `_followLatest = true`。
- **隐藏**：滚到底或列表空。

### 4. 时序（非跟底）

```
WS create → upsertRecord
         → (skip scroll if !followLatest)
         → postFrame ×2 → measure anchor
         → if anchor below viewport: end = historyArea.bottomCenter
         → else: end = anchor.center
         → fly animation
```

### 5. 时序（跟底）

与现网相同：upsert → scrollToBottom → measure → fly。

### 6. 其它（不变）

- recordId 锚点 GlobalKey；并发取消上一动画；disableAnimations 跳过 Overlay。
- 跟底时 disableAnimations：仍 upsert + 滚底，不飞。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 屏外锚点测点失败 | 回退飞向历史区底缘中心 |
| 回底按钮挡内容 | 小尺寸正圆、0.3 透明主色填充；仅非底部显示 |
| 跟底与 fly 竞态 | 分支明确；双 postFrame |

## Migration Plan

- 调整 `HomeHistoryScroll`：新 record 滚底改为 **仅 `_followLatest`**（需从 parent 传入或内部监听 scroll）。
- 纯客户端；可回滚 Overlay + 按钮。

## Open Questions

- 非跟底时动画落点用「底缘中心」还是「锚点真实 global（可能飞出屏）」？**当前：底缘中心**（更易看见）。

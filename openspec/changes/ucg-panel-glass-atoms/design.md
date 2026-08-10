## Context

`panelGlass*` 已在 `theme-panel-glass-atoms` 落地并接入预测 chrome。UCG 侧仍：

- `UcgFeedFakeGlassPanel` → `contentCard` 近白起笔 + `textOnContentCard`
- 辩论 VS / 马卡龙 → `UcgDebateVisualTokens` 内 `Color(0x…)` 与大量 `Colors.white`
- 壳文案经 `UcgTheme.onShell` / `tokens?.onShell` 旁路 `AppColor`

用户要求：广场与辩论卡跟预测 chrome 同源暗浮层；契约对齐；类别色原子化；业务无硬编码色。

## Goals / Non-Goals

**Goals:**

- 广场假玻璃 + 辩论 Feed/分享卡外壳 → `panelGlassGradient` + `textOnPanelGlass*`。
- 辩论左右侧（渐变、标签、百分比、VS 边/钮相关色）升为原子 API；widget 只选角色。
- UCG 业务取色经 `AppColor`（`UcgTheme` 仅转发）；清扫卡底/正文/描边硬编码。
- 夜空主题下广场/辩论卡不呈大面积近白。

**Non-Goals:**

- 不改主页历史日卡等非 UCG 的 `contentCard` 浅卡策略。
- 不重做辩论交互/布局；仅色与取色路径。
- 不强制一次扫清全仓非 UCG 硬编码（本 change 以 `app/lib/ucg/**` 为主）。
- 不新建测试文件。

## Decisions

### D1：外壳复用既有 panelGlass（不新造 Feed 暗卡角色）

```
UcgFeedFakeGlassPanel
  fill   → AppColor.panelGlassGradient(accent: eventAccent?)
  border → AppColor.divider（或 panel 边若后续加原子）
  text   → AppColor.textOnPanelGlass / Muted
```

与预测事件卡同族；可选 `eventAccent` 走 B 路径。

### D2：辩论类别色 → `AppColor` 辩论角色（常量迁入派生/token）

将现 `UcgDebateVisualTokens` 中的马卡龙色升级为语义角色，例如：

| 角色 | 用途 |
|------|------|
| `debateSideLeftGradientStart/End` | 左侧条渐变 |
| `debateSideRightGradientStart/End` | 右侧条渐变 |
| `debateSideLeftLabel` / `Percent` | 左侧字 |
| `debateSideRightLabel` / `Percent` | 右侧字 |
| `debateVsChipFill` / `Border` / `onChip` | 中心钮与描边（原白边白底） |

实现优先：`AppVisualTokens` 成对字段 + `AppColor.debate*` 入口；`UcgDebateVisualTokens` 仅保留半径/emoji 等非色几何常量，色 API 删除或改为转发 `AppColor`。

左右侧色可随壳明暗微调（暗壳略降饱和/提亮字），但 **禁止** 在 `ucg_debate_vs_bar.dart` 内再写 `Color(0x…)`。

### D3：UcgTheme 薄转发

`UcgTheme.onShell` → `AppColor.textPrimary`；`onRecordsCard` → 若仍被非 panel 路径调用，标明废弃倾向并指向 `textOnContentCard` / `textOnPanelGlass`（按场景）。新代码 MUST 直接 `AppColor`。

### D4：允许的原子化例外（仍须入口，禁止散落）

| 场景 | 原子方向 |
|------|----------|
| 媒体全屏/viewer 黑底白字 | `barrier` 或新增 `mediaScrim` / `onMediaScrim`（本 change 至少收口到 AppColor 一处） |
| 删除红滑块 | `colorScheme.error` / `onError` |
| 透明占位 | 可用 `Colors.transparent`（非「类别色」） |

### Alternatives considered

- 继续 contentCard 浅卡 + 只改字色：否决（夜空仍白卡）。
- 马卡龙保留 widget 常量「品牌例外」：否决（用户要求类别色原子化、无硬编码）。
- 把辩论色并进 panelGlass accent：否决（左右双色不是单 accent）。

## Risks / Trade-offs

- [马卡龙迁原子后观感偏移] → 初值对齐现有 hex；矩阵夜空/经典各验左右可辨。
- [VS 白边改 divider 后对比变弱] → 用 `debateVs*` 原子保证相对 panelGlass 可读。
- [与未归档 theme-panel-glass-atoms 重叠] → 本 change 只消费已有原子；不重复改预测页。

## Migration Plan

- 纯客户端。回滚：恢复 `UcgFeedFakeGlassPanel` contentCard 与辩论 hex 常量。

## Open Questions

- （无）广场/辩论挂 panelGlass、类别色原子、契约对齐已确认。

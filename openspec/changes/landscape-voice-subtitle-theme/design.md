## Context

`_LandscapeVoiceSubtitleToast` 使用 `Colors.black.withValues(alpha: 0.45)` + `AppColor.textPrimary`；浅色/彩色壳上对比与主题脱节，且违反「业务色经 AppColor / 禁止内联拼色」。`_LandscapeVoiceListenChip` 已用 `panelGlassTop` + `textPrimary`，红绿点仍为硬编码 hex。产品选项 C：弹幕 + chip 成套主题化，并加轻微出现动效/圆角对齐。

约束：`openspec/project.md` 主题语义原子；浮层角色用 **panelGlass**（非 contentCard、非随意 mediaScrim）；不改 voice 会话逻辑。

## Goals / Non-Goals

**Goals:**

- 弹幕底/字/边走 panelGlass 族，随主题切换可读。
- chip 与弹幕同一浮层语言；连接点用 Theme/`ColorScheme` 语义色，去掉业务马卡龙 hex。
- 弹幕短淡入；圆角/内边距与 chip 视觉族接近。

**Non-Goals:**

- 不改字幕出现/清空时机、idle、WS、KWS。
- 不新增 `AppColor` success token（除非实现中发现 `ColorScheme` 无法表达且评审同意扩 token）。
- 不做复杂弹幕动画（滚动弹道、粒子等）。

## Decisions

1. **弹幕表面 = panelGlass**  
   底：`AppColor.panelGlassGradient` 或 `panelGlassTop`（可略提 alpha 保证压在瀑布流上可读）；字：`textOnPanelGlass` / muted；可选细描边 `onPanelGlass` 低 alpha。  
   备选 mediaScrim → 否决（媒体沉浸语义过重）。  
   备选继续黑底 → 否决（不随主题）。

2. **chip 对齐**  
   底继续/统一 panelGlass；文案改 `textOnPanelGlass`（压在 glass 上，比 onShell 更配对）；mic 高亮仍 `colorScheme.primary`。  
   连接点：未连 → `colorScheme.error`；已连 → `colorScheme.tertiary` 或 `primary`（文档写清「已连指示」）。若 tertiary 在某预设过淡，实现时选对比更强的 scheme 色并注释。

3. **轻动效**  
   弹幕用 `AnimatedOpacity` / 短 `FadeTransition`（约 150–250ms），仅在文本从空→非空或 Widget 插入时；不引入新依赖。  
   圆角：弹幕与 chip 统一约 16–20（chip 已 20，弹幕可从 12 提到 16）。

4. **范围文件**  
   仅 `smart_prediction_screen.dart` 两私有组件；必要时抽极小本地 helper，不新建主题文件。

## Risks / Trade-offs

- [浅壳 panelGlass 偏透、字幕压花屏] → 略提高不透明度或加边；真机切换 2–3 套调色板验收。  
- [error/tertiary 在个别预设对比弱] → 实现时选可读 scheme 色；仍禁止裸 hex。  
- [淡入与快速换字幕打架] → 同 key 文本更新不重启长动画，或仅首次出现 fade。

## Migration Plan

1. 改 toast → 改 chip 点/字 → 加淡入与圆角。  
2. 真机切换主题看弹幕/chip。  
3. 回滚即恢复黑底/旧 hex。

## Open Questions

- （无阻塞）已连指示用 `tertiary` 还是 `primary`：实现时以暗/浅壳对比为准，design 允许二者择一并注释。

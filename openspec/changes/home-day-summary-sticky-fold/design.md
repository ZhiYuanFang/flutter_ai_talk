## Context

`home-per-day-summary-sticky` 已把汇总挂进日期吸顶，但 `SliverPersistentHeader` 的 extent 来自 `estimateHomeDayStickyExtent`（按 chip 数 / 假定均宽估行数）。估高偏大时 `Align(top)` 留下底部空白；且默认展开全部折行。旧独立今日汇总曾用测高 + 两行折叠；产品现要求：**真高** + **默认一行** + 日期旁展开/收起。

## Goals / Non-Goals

**Goals:**

- 吸顶高度 = 当前展示态下内容实测高度（无多余空白、无长期裁切）。
- 默认一行 chip；需要时展开看全部；收起回一行。
- 展开控件在日期行右侧，与 chip→Sheet 分离。
- 每日本地独立 `isExpanded`。

**Non-Goals:**

- 改聚合/日键/Sheet/usage。
- 全局单一展开开关。
- 恢复身份头下独立今日汇总条。

## Decisions

1. **测高驱动 extent**  
   对每个 `dayLocal` 缓存 `collapsedExtent` / `expandedExtent`（或单一 `extent` + 展开标志）。首帧可用保守估高（日期+1 行），Offstage/`GlobalKey` 测真高后 `setState` 写回；差值小于 0.5px 不更新，避免抖动。

2. **折叠交互**  
   仅当「全高 > 一行高」（或测得 needsFold）时显示「展开」/「收起」。默认 `isExpanded=false`。点日期行右侧 TextButton；chip `onTap` 仍只开图。

3. **一行高**  
   收起：`ClipRect` + `maxHeight ≈ 单行 chip（~28）`（与旧面板 `_twoRowMaxHeight` 类似，但阈值改为一行）。展开：不裁切。

4. **按日状态**  
   `HomeHistoryScrollState` 内 `Map<DateTime, bool> _daySummaryExpanded`；日键与分组 `dayLocal` 一致。列表重建保留同键状态。

5. **估高函数**  
   可保留作首帧 fallback；稳态以实测为准。

## Risks / Trade-offs

- [测高后 extent 变化导致滚动跳] → 仅增加/减少 header 高度时尽量在非跟底场景接受微小位移；跟底时可 reanchor。  
- [展开后吸顶过高] → 产品接受；可再滚。  
- [多日同时测高] → 按可见日测，或首建日测一次。

## Migration Plan

1. 日期头加折叠 UI + 测高回调。  
2. Scroll 持有展开态与 extent 缓存。  
3. 手工：无空白；默认一行；展开/收起；chip 仍开图。  
4. 回滚：恢复估高全展开。

## Open Questions

- （已定）默认一行；日期右侧展开；按日独立；实测高度。

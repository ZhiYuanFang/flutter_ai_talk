## Context

趋势中心（`TrendsScreen` + `TrendGlassBarChart`）现为单全屏玻璃柱图：上方大 logo、标题行左事件右 `MM-dd — MM-dd`、自由日历 Sheet、范围持久化（≤30 日）、同日小时桶/跨日日桶切换。数据经 `RemoteTrendsRepository.loadSeries` 聚合为 `TrendSeries` 后丢弃原始发生时刻。产品探索结论要求双图联动、预设近 N 日、按 `eventType` 分画法，且保留事件选择记忆、取消范围记忆。

约束：对照 `openspec/specs/v2.1.0.md` 中 `trends-center-*`；事件品牌色为例外（可用 accent）；不新建测试；不改原生。

## Goals / Non-Goals

**Goals:**

- 预设范围：近7日（默认）/ 近15日 / 近1个月；UI **不出现**近3个月；不持久化范围。
- Chrome：选择行 `[logo][事件名 ▾]` + 右侧范围文案；飞入落点=选择行 logo；上/下图标题均含 logo 且事件色居中。
- 双图：近 N 日总量柱图 ↔ 选中某日详图；纵屏上下均分、横屏左右均分。
- 近 N 日：Y 轴 3 刻度；柱；顶标仅选中柱；计次柱内散点（柱高映射 24h）。
- 某日：计时/计数折线+折点量标；计次时间轴（无数值 Y、四时段底、点下细线+时刻）。
- 选中日状态机与无数据骨架态。

**Non-Goals:**

- 近3个月 / >30 日查询。
- 自由日历选日、范围 SharedPreferences 恢复。
- 主页今日小时趋势 Sheet 行为变更。
- 服务端 piece API 契约变更。
- 同时刻多发生点的复杂防重叠算法（允许轻微重叠或简单错开，实现阶段择简）。

## Decisions

1. **范围模型：预设天数 → 本地起止日**  
   `end = today`，`start = today - (n-1)`，n∈{7,15,30}。Sheet 三选项，无「近3个月」。停用 `TrendsDateRangeStore.loadValid/save` 于进页/确认路径（可保留文件但不再读写，或明确废弃调用）。  
   *备选*：保留日历 — 已否决。

2. **一次拉 piece，派生双图**  
   按起止 Unix 拉取 raw 点（含时刻）；上图 `fillTrendBucketsDaily`；下图由选中日过滤：计时/计数 → `fillTrendBucketsHourlyFullDay`（或今日用 today 变体）；计次 → 发生时刻列表。换选中日不重复 HTTP。换事件/范围才重新请求。  
   *备选*：选日再请求同日 piece — 多一次 RTT，无必要。

3. **布局拆分**  
   `TrendsScreen` 负责 chrome + `OrientationBuilder`/`MediaQuery` 均分（`Column`/`Row` + 两个 `Expanded`）；近 N 日柱图与日详图拆为独立 widget（可演进现有 `TrendGlassBarChart`，避免单文件继续膨胀）。图标题在各自区域内居中，不与 chrome 行混排。

4. **Y 轴固定 3**  
   近 N 日柱图与计时/计数某日折线图：`ChartAxisGranularity.glassLeftTitles` 调用时强制 `landscape: false` 语义或新增 `yLabelCount: 3` 参数，使趋势双图恒 Y3（不强制改主页小时图横屏 Y5）。

5. **计次柱内散点**  
   柱高编码日总量；每条发生的本地时刻 `t` 映射 `y = (hour + minute/60) / 24 * barHeight`（相对柱底）；深色圆点叠在柱内。仅 `eventType == one`。

6. **计次某日时间轴**  
   无数值 Y；背景四段 `00–06 / 06–12 / 12–18 / 18–24`，段底色与事件 accent `Color.lerp` 或 alpha 叠色；发生点落在 0–24 轴上，点下短细线，线末端下方 `HH:mm`。可用 `CustomPainter` / Stack，不必强绑 fl_chart。

7. **量标单位**  
   计时：时分（复用 `formatTodayTotalAmount` 同类逻辑）；计数：数值 + `EventDefinition.unit`；计次：固定「次」。柱顶标仅选中柱。

8. **选中日**  
   状态字段本地自然日；默认今日；不持久化。换事件不变；换范围若 `selected ∉ [start,end]` 则今日。点击上图柱切换。

9. **骨架**  
   选中日无记录（含今日）时下图展示轴/轨道占位骨架，禁止「暂无数据」类文案；上图该日柱可为 0 并保持选中。

10. **Logo 飞入**  
    `GlobalKey` 绑在选择行左侧 `EventLogo`；去掉原 header 大 logo 测点。

## Risks / Trade-offs

- **[Risk] 近30日高密度计次标注重叠** → 点下细线+时刻允许重叠；后续可再做避让。  
- **[Risk] 停用范围记忆后旧 prefs 残留** → 忽略即可，不读即无行为。  
- **[Trade-off] 破坏「仅柱图」规格** → 日详图引入折线/时间轴；用 MODIFIED/REMOVED 更新 `trends-center-glass-bars`，新能力承接日详图。  
- **[Trade-off] 三处 logo** → 产品明确要求；注意小尺寸槽位与飞入仅瞄选择行。

## Migration Plan

1. 落规格 delta → 改范围 Sheet/默认 → 双图壳与选中日 → 柱图增强 → 日详图/时间轴 → 飞入落点 → 去掉记忆调用。  
2. 手工：三类事件、三预设、纵/横屏、无数据骨架、换事件保日/换范围越界回今日。  

回滚：恢复单图 + 日历 Sheet + store 读写。

## Open Questions

- 无（时段均分、近3个月不出现、计次下图形态已确认）。

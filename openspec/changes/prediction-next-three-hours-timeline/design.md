## Context

智能预测页已有 `predictionCareAlertProvider`（值得留意）与 `smartPredictionRowsProvider`（含 `nextAt` / 推演开关）。时间线插在留意跑马灯与事件卡片 `Expanded` 之间。

## Goals / Non-Goals

**Goals:**

- 有窗内预测时展示「接下来3小时」时间线（不要求留意非空）。
- 含超时、窗内全量、折行+展开/收起、点击回喂养页。

**Non-Goals:**

- 不新拉 HTTP；不改留意算法与卡片瀑布流。
- 不新建测试文件。

## Decisions

1. **窗口**  
   `forecastEnabled && prediction != null && nextAt <= now + 3h`（含 `nextAt < now`）；升序。无下限截断逾期。

2. **显隐**  
   `timelineSegments.isNotEmpty` 即挂载；与留意列表解耦；无窗内段落则整块不出现。

3. **文案**  
   每段：`HH:mm 左右{eventName}`（本地时区，两位补零）；`join(' → ')`。标题固定「接下来3小时」。

4. **展开**  
   默认 `maxLines: 2`（或等价高度）；`expanded` 时不限行。整块 `InkWell`：先若可溢出则切换展开，或点击始终切换且同时/额外跳转？  
   **产品：点击跳转喂养主页**；展开/收起也需点击——采用：  
   - 短按/单击整块 → **跳转喂养**；  
   - 右侧「展开/收起」小链或第二次交互？  
   更干净：**正文区点击 = 跳转**；标题行旁提供「展开」文字按钮仅切换折叠（避免与跳转冲突）。  
   若产品坚持「点击」兼两者：首次点展开，已展开再点跳转——易懵。  
   **定案**：整卡点击 → 喂养页；单独「展开/收起」控件（文案或 chevron）只改折叠，不导航。

5. **导航**  
   `ref.read(homePagerRequestProvider.notifier).requestPage(HomePagerPage.feeding)`（与现网喂养跳转一致）。

## Risks / Trade-offs

- [逾期过多占满时间线] → 产品接受窗内全量；后续可加逾期上限。  
- [展开与跳转手势冲突] → 分拆控件（见上）。

## Migration Plan

- 纯 UI；热重载即可。

## Open Questions

- （无）展开用独立控件已写入决策，避免与跳转冲突。

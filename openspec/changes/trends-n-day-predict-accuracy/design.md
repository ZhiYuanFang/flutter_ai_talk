## Context

趋势中心 `TrendNDayBarChart` 已按自然日画选中事件的总量柱；选中柱有量顶标。预测准确度地基为 history `expectStartTime`（及可选 end/amount），仅 add 打戳、禁止重放。产品确认：在**量柱上方**展示**当日**准确率，不是另画准确率柱。

## Goals / Non-Goals

**Goals:**

- 每个有合格样本的自然日，在对应量柱上方显示整数 `%`。
- 计分范围 = 当前选中事件根 + 柱图同一 N 日窗。
- 遵守「仅有 expect* 才计分、不重放」。

**Non-Goals:**

- 独立准确率柱 / 替换量柱。
- 服务端聚合 API。
- duration/amount 准确率（可后续）。
- 预测页折线卡、喂养首页。

## Decisions

1. **展示位置**  
   每柱上方准确率文案（`topTitles` 或等价 overlay）。无合格样本的日子 **省略** 标签（不画「—」）。选中柱的**量**顶标逻辑不变；准确率始终按日尝试展示（有样本即显示，不限选中）。

2. **计分范围**  
   与柱图相同：`EventDefinition` 选中项所属根下、occurrence 落在该自然日的历史行。根解析与趋势聚合现有 root 规则对齐。

3. **合格样本**  
   rawPayload 含可用 `expectStartTime`（正 unix 秒）。缺 expect* 的行跳过。实际开始取记录 `startTime`（与 history 秒语义一致）。

4. **v1 命中规则**  
   `|actualStartSec − expectStartTime| ≤ 1800`（30 分钟）→ 命中。  
   日准确率 = `round(100.0 * hits / samples)`，展示如 `85%`。  
   samples=0 → 不展示。

5. **文案色**  
   跟随事件 accent；可选：≥70% 用不透明度更高、&lt;70% 略淡（轻量档，非第二套色板）。

6. **数据源**  
   趋势页已加载的 history / trend raw 同源列表；客户端内存聚合。不新拉专用准确率接口。

## Risks / Trade-offs

- [打戳前无样本] → 多日无 %，可接受。  
- [仅 start 维] → duration/amount 事件准确率偏「到点」语义，后续可加维。  
- [30 分钟窗] → 产品可调；写死常量便于 v1。  
- [与量顶标重叠] → 准确率在上、量标仍用 fl_chart 选中 tip；注意 padding。

## Migration Plan

1. 依赖 expect* 已上线客户端与服务端。  
2. 回滚：停画准确率 top 标签即可。

## Open Questions

- 无（explore 未回时采用：每柱一日、选中事件根、30 分钟命中、无样本省略）。

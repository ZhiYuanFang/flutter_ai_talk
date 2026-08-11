## Context

量身定做单卡在确认后进入思考盖层（打字机），结束后需点「继续」；叶子用 `ChoiceChip` 必选；`_FloatingCard` 用 `AppModalGlassPanel` 未传 `eventAccent`；标题无 logo。

## Goals / Non-Goals

**Goals:**

- 思考文案打完后约 **400ms** 自动 `_advanceToNextRoot`（含收尾页）。
- 子事件：有 `childrenOf` 真子节点时只读展示「该事件包含」；无子则整区隐藏；去掉选择态。
- 种子 `leafEventId = root.id`。
- 标题行：`EventLogo` + 事件名。
- 卡壳：`eventAccent: resolveEventColor(context, root)`（思考盖层用当前根）。

**Non-Goals:**

- 不按每个子事件各写一条种子。
- 不改玻璃时间/间隔 picker（见 `recall-picker-atoms`）。
- 不改收尾页必须跟某事件色（可用主题色）。

## Decisions

1. **自动跳转**  
   打字机 `>= full.length` 时 cancel timer，再 `Future.delayed(400ms)` 后 advance（mounted 守卫）。「跳过动画」：补全文后同样走延迟自动跳（可不强制再点继续；底部按钮可改为仅「跳过动画」或隐藏完成态按钮）。

2. **子事件判定**  
   `final kids = childrenOf(catalog, root.id)`；`kids.isEmpty` → 不展示；否则只读 chips/文本，无 `onSelected`。

3. **种子**  
   `leafEventId: root.id`；思考文案去掉「具体是「叶」」分支。

4. **视觉**  
   `_FloatingCard` 增加 `eventAccent` 参数；PageView 业务卡与思考盖层传入当前根色；finale 可不传。

## Risks / Trade-offs

- [自动跳过快读不完] → 400ms 缓冲；可点跳过动画提前结束打字。  
- [根 id 种子粒度变粗] → 产品接受信息只读；预测仍按根节奏。

## Migration Plan

纯客户端；无迁移。

## Open Questions

- （无；延迟 400ms、leaf=root 已作默认）

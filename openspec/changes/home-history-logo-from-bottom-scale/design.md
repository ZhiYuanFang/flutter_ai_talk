## Context

`HomeHistoryTimelineTile` 已用 `fontSize = (13 - fromBottom * 0.35).clamp(9.0, 13.0)` 与 `emphasis` 做底大上小；圆点仅最新/非最新两档。`EventLogo` 使用常量 `logoSize = 16`。explore 已锁定策略 **A**：logo 跟 base 字号同坡，不跟事件名 1.5×。

## Goals / Non-Goals

**Goals:**

- logo 随 `fromBottom` 与正文 base `fontSize` 同比例缩放。
- 最新约 16；旧行下限约 10–11；行高 ~40 不变。

**Non-Goals:**

- 按事件名 1.5× 缩放 logo。
- 改圆点为连续衰减；改相对 ago 布局语义；改飞入/停止/WS。
- 按钮网格、预测卡、吸顶汇总 chip 的 logo。

## Decisions

1. **公式**  
   `fontSize = (13 - fromBottom * 0.35).clamp(9.0, 13.0)`（与现网一致）  
   `logoSize = (16.0 * fontSize / 13.0).clamp(10.0, 16.0)`  
   抽静态方法如 `logoSizeForFromBottom`，供 tile 与（若需要）inset 复用。

2. **槽位**  
   `SizedBox` / `EventLogo(size:)` 使用该行动态尺寸；外圈 padding/阴影可保持 2px（只缩图）。

3. **badge 左 inset**  
   继续按最大 16 估算 `timelineBadgeLeftInset`（简单、旧行略偏右可接受）。不强制按行动态 inset。

4. **飞入**  
   锚点 `GlobalKey` 测实际槽位中心；无需改 fly 管线。

## Risks / Trade-offs

- [估高/行内拥挤] → clamp 上限 16、行高不变。  
- [badge 与变宽 logo 未对齐] → 接受用 max 16；若观感差再 follow-up。  
- [与字号公式漂移] → 单处计算 fontSize 再推 logo，避免两套 fromBottom 系数。

## Migration Plan

1. 改 `HomeHistoryTimelineTile` 动态 logo。  
2. 手工：底行 logo 明显大于上滚旧行；飞入仍落 logo。  
3. 回滚：恢复常量 16。

## Open Questions

- （已定）策略 A：跟 base 字号。  
- （已定）badge inset 用 max 16。

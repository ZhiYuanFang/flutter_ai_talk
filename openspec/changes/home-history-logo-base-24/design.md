## Context

`home-history-logo-from-bottom-scale` 已落地 `logo = 16 * fontSize/13`（clamp 10–16）。产品反馈底行仍偏小，要求锚点 ×1.5 → **24**，同坡，下限仍 **10**。

## Goals / Non-Goals

**Goals:**

- `logoSizeMax = 24`；`logoSizeForFromBottom = (24 * fontSize/13).clamp(10, 24)`。
- badge / 飞入峰值基准用 24。

**Non-Goals:**

- 改字号公式、事件名 1.5×、行高策略（仍约 40）。
- 抬高旧行下限到 15（明确保持 10）。

## Decisions

1. **常量**  
   `logoSizeMax`：16 → 24；`logoSizeForFromBottom` 分子同步；floor 保持 10.0。

2. **行高**  
   24 + padding≈4 仍小于 40；接受底行 logo 更满，不改 `rowHeight`。

3. **引用点**  
   `history_event_fly_overlay` 的 `logoSizeMax` 自动跟上。

## Risks / Trade-offs

- [底行略挤] → 接受；若裁切再开 follow-up 微调 padding。  
- [旧行 10 相对 24 对比更强] → 产品已选下限 10。

## Migration Plan

1. 改 `logoSizeMax` 与公式。  
2. 热重载目视：底 24、上更小、不低于约 10。  
3. 回滚：max 回 16。

## Open Questions

- （已定）底 24、同坡、下限 10。

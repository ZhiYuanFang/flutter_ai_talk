## Why

按日时间层次已让 logo 随 `fromBottom` 衰减，但底行仍约 16px，最新记录不够突出。产品要求底行再放大 1.5×（24），并仍按 base 字号同坡向上缩小，下限保持 10。

## What Changes

- 最新行（`fromBottom == 0`）`EventLogo` 边长 MUST 约为 **24**（相对原 16 的 1.5×）。
- 衰减公式 MUST 仍与 base `fontSize` 同坡：`logoSize ≈ 24 * fontSize / 13`，clamp **约 10–24**。
- MUST NOT 改事件名 1.5× 文案规则；MUST NOT 用两档替代连续衰减。
- 行高约 40、飞入锚点、badge inset 按新 max（24）估算。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-history-timeline-row`：将 EventLogo 底边长与缩放锚从 16 调整为 24，下限仍约 10。

## Impact

- UI：`home_history_timeline_tile.dart`（`logoSizeMax` 16→24）；飞入 overlay 峰值基准随 max。
- 对照：`home-history-logo-from-bottom-scale`。

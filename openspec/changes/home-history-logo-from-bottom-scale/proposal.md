## Why

喂养历史时间轴行正文已随 `fromBottom` 衰减（底大上小），但 `EventLogo` 固定 16px，旧行字缩小后 logo 仍一样大，时间层次被钉死。应对齐 base 字号坡度，让 logo 同步衰减。

## What Changes

- 主页历史时间轴行的 `EventLogo` 尺寸 MUST 随该行 `fromBottom` / base `fontSize` 连续缩放：最新行保持现网约 16；随 `fromBottom` 增大按与正文相同的 `(13 - fromBottom×0.35).clamp(9,13)` 比例缩小（`logo ≈ 16 × fontSize/13`），下限约 10–11。
- **不**按事件名 1.5× 视觉字号放大 logo；**不**改为圆点式「仅最新/非最新」两档。
- 行高约 40、单行布局、飞入锚点、停止计时等行为 MUST 保持；相对 ago 左 inset MAY 继续按最大 logo 宽估算。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-history-timeline-row`：新增 EventLogo 随 `fromBottom` 与 base 字号同坡衰减的 Requirement。

## Impact

- UI：`home_history_timeline_tile.dart`（`logoSize` 由常量改为按 `fromBottom` 计算）。
- 飞入落点仍测实际 logo 槽；不改预测页 / 按钮网格 logo。
- 基线：`openspec/specs/v2.1.4.md` → `home-history-timeline-row`（含既有字号衰减 Requirement）。

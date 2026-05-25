## Why

主页底部按钮模式的事件网格当前相邻按钮间距偏大（列宽 72px、间隔 8px），同屏可见按钮数偏少，视觉上也显得松散。缩小按钮间距可在不改变交互的前提下提高信息密度，让底部区域更紧凑。

## What Changes

- 缩小 `HomeButtonEventGrid` 相邻事件按钮之间的**水平间距**（`kHomeEventButtonColumnGap`）。
- 适度缩小单列固定宽度（`kHomeEventButtonColumnWidth`），使 logo + 名称布局仍可读、可点。
- 可选微调列表左右 `padding`，与更紧凑的列宽一致。
- **不**改变按钮点击行为、事件类型逻辑与底部面板总高度策略（`kHomeButtonInputPanelHeight` 仍由网格高度推导，若行高不变则面板高度不变）。

## Capabilities

### New Capabilities

- （无独立新能力；属现有按钮网格视觉调优。）

### Modified Capabilities

- `home-button-input-mode`（变更 `home-button-input-mode`）：补充/调整两行（现实现为单行横向）事件按钮网格的**列间距与列宽**紧凑化要求。

## Impact

- `app/lib/ui/home_button_event_grid.dart` — 间距与列宽常量。
- 无 API / 网关变更；无路由变更。

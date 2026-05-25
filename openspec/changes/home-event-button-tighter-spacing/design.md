## Context

- 底部按钮模式：`HomeButtonEventGrid` 单行横向 `ListView.separated`。
- 当前常量：`kHomeEventButtonColumnWidth = 72`、`kHomeEventButtonColumnGap = 8`、列表 horizontal padding `8`；cell 内 logo 40px + 4px + 两行 label。
- `kHomeButtonInputPanelHeight = kHomeEventButtonGridHeight + 8`（行高 68 不变则面板高度不变）。

## Goals / Non-Goals

**Goals:**

- 相邻按钮视觉间距明显缩小，同屏多展示约 1 个按钮。
- 保持 logo 40px、名称最多 2 行、最小点击区域可接受（列宽 ≥ 60）。
- 常量集中修改，便于后续微调。

**Non-Goals:**

- 改回双行网格（与现网单行实现不一致，不在本变更范围）。
- 修改 logo 尺寸、字体或事件 catalog 数据。
- 调整语音/文字输入模式布局。

## Decisions

| 常量 | 现值 | 新值 | 说明 |
|------|------|------|------|
| `kHomeEventButtonColumnGap` | 8 | **4** | 主要缩小「按钮之间」间距 |
| `kHomeEventButtonColumnWidth` | 72 | **64** | 列略窄，名称仍 2 行 ellipsis |
| ListView horizontal padding | 8 | **6** | 与整体紧凑一致 |

**备选**：仅改 gap 不改 width — 用户反馈「间距」偏大，列宽一并略减效果更好。

**验证**：320dp 宽屏上可见按钮数对比；长事件名 2 行截断仍正常。

## Risks / Trade-offs

- **[Risk] 极窄屏误触** → 列宽 64 仍大于 Material 最小推荐的一部分，InkWell 整列可点。
- **[Trade-off] 更密 vs 可读性** → 名称 font 不变，仅水平更紧。

## Migration Plan

- 纯 UI 常量发布，无迁移。

## Open Questions

- （默认）若仍觉偏宽，可后续仅再调 gap 至 2；本变更先 4/64/6。

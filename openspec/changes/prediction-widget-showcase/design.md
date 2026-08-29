## Context

基线 `home-feed-upcoming-widget` 已提供 Android/iOS 三尺寸桌面小组件与 Flutter payload sync。设置页曾有 `HomeWidgetSettingsSection`（行列表预览 + 刷新），现已注释。预测主路径无发现入口。`home_widget ^0.9.3` 提供 `getInstalledWidgets()` 可区分是否已钉。

## Goals / Non-Goals

**Goals**

- 竖屏预测悬浮入口 + 展示页两态（未钉 / 已钉）。
- large Flutter 预览神似原生大图（视觉 token / 信息架构对齐）。
- 已钉可刷新桌面数据；未钉只教添加。

**Non-Goals**

- 不预览 small/medium；不改 native XML/SwiftUI。
- 不强制 `requestPinWidget`（可为后续增强）。
- 不恢复预测底 tip 跑马灯；不开关屏语音。

## Decisions

### D1：安装态

- `hasPinnedWidget = (await HomeWidget.getInstalledWidgets()).isNotEmpty`。
- 可选过滤胖宝 Provider class / iOS kind；首版空列表判定即可。
- 失败 / Web → 视为未钉（引导添加）。
- 预测页可见与 App resume 时刷新；展示页 `initState` / resume 再读一次。

### D2：入口

- 仅竖屏 + Android/iOS；叠在预测 Stack 底部（避开安全区）。
- 列表底部留白，避免最后一行被挡。

### D3：展示页两态

| | 未钉 | 已钉 |
|--|------|------|
| FAB / 入口文案 | 添加桌面小组件 | 查看桌面小组件 |
| 顶区 | 分平台添加说明 | 能力说明 |
| large 预览 | ✓ | ✓ |
| 刷新 | ✗ | ✓ → `ensureWidgetReadyFromRef` |

### D4：large 预览

- 独立 Widget，消费与 sync 同源的 rows / header / visual（`buildWidgetRows(..., kind: large)` + theme visual）。
- 神似：渐变壳、圆角、头、tip、事件行；不追求与 RemoteViews 像素一致。
- 覆盖 empty / loading / ready。

### D5：路由

- go_router 新路径（如 `/widgets/showcase`）；从预测 FAB push。

## Risks / Trade-offs

- [iOS/Android 安装态延迟] → resume 刷新；文案短暂不准可接受。
- [预览与桌面观感差] → 共用 visual payload；对照 large layout 结构。
- [FAB 挡内容] → 底 padding。

## Migration Plan

- 纯加性；无数据迁移。回滚删路由与 FAB 即可。

## Open Questions

- （无阻塞）设置页是否链到新页：实现时可保持注释。

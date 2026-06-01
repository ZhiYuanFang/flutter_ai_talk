## Context

- `home_screen.dart`：`Expanded` + `ListView.builder(reverse: true)`，每项 `Opacity(0.4→1)` + `Text.rich(historyLineSpans)`，垂直 padding 约 7px/条。
- `history_line_format.dart` 已区分 `eventNumber` 各态（计数、计时中、用时）；主页可复用同一解析，仅改变**排版**。
- 上方已有 `HomeTodaySummaryPanel`；历史行应避免重复冗长「今日」时间前缀（仍用 `formatHistoryInstant` 规则）。
- 规范约束（`home-input-history-sse`）：最新锚定底部、向上变弱、越往上字号不增。

## Goals / Non-Goals

**Goals:**

- 时间轴行：左列时间（约 44–52px 宽）、中间事件名加粗、右列尾注（`->3` / `开始计时` / `用时X分钟` / 备注截断）。
- 行高紧凑（目标 **34px** `itemExtent` 或等价最小高度），列表仍占 `Expanded`。
- 顶部渐变：旧记录在视觉上淡出，底部最新一条最清晰。
- 保留 `reverse: true` 与点击 `/_history/:id`。

**Non-Goals:**

- 历史区改为折叠/二级页、减少 `pageSize`、改动 SSE/接口。
- 重做今日概览 chips。
- 修改历史详情页排版。

## Decisions

### 1. 行结构（时间轴）

```
[时间]  [事件名………………]  [尾注]
 44px      Expanded          trailing
```

- **时间**：`formatHistoryInstant` 结果；`labelSmall`、`onSurfaceVariant`。
- **事件**：`eventName`；`labelMedium` + `FontWeight.w600`；备注 `(remark)` 并入中间区，`maxLines: 1`。
- **尾注**：由 `eventNumber` 推导——`>1` 显示 `→n`；`==0` 未结束 `开始计时`；已结束 `用时…`；`==1` 无数字则仅事件+备注。
- **时间轴装饰**：最底可见项（index 0 in reverse builder 的 `fromBottom==0`）左侧圆点用 `primary`；其余 `outlineVariant`；竖线可选 1px（同列），不增加行高。

### 2. 紧凑与层次

| 项 | 值 |
|----|-----|
| 行高 | `visualDensity: compact`，垂直 padding 0–2 |
| 字号梯度 | 底部 13px → 顶部 11px（`fromBottom` 映射，下限 11） |
| 对比 | 底部 `onSurface`；顶部 `onSurface` @ 0.55 alpha；**去掉** per-item `Opacity` |
| 顶渐变 | `ShaderMask` 包 ListView，`Alignment.topCenter` 线性渐变 transparent→black，高度约 48–64px |

### 3. 展示数据抽取

新增 `HistoryHomeRowDisplay fromRecord(HistoryRecord, DateTime now)` in `history_line_format.dart`：

```dart
class HistoryHomeRowDisplay {
  final String timeLabel;
  final String eventName;
  final String? middleRemark; // optional
  final String trailing;      // ->3, 开始计时, 用时, empty
}
```

`HomeHistoryTimelineTile` 只消费该模型，避免 Widget 内重复分支。

### 4. 列表集成

```dart
ShaderMask(
  shaderCallback: (rect) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black],
    stops: [0, 0.12], // 顶部 12% 淡出
  ).createShader(rect),
  blendMode: BlendMode.dstIn,
  child: ListView.builder(reverse: true, ...),
)
```

- `padding` 保持左右 16；`itemCount` 不变。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| ShaderMask 导致点击区域怪异 | `blendMode: dstIn` 仅影响绘制；或改用 Stack 顶层渐变 Decorator 不裁切 hit test |
| 备注一行截断 | 详情页可看全文；主页以扫读为主 |
| 与 OpenSpec「渐隐」表述差异 | delta spec 写明渐变等价满足「向上变弱」 |
| 时间轴竖线对齐 | 首版可仅圆点，竖线 v2 再加 |

## Migration Plan

- 纯 UI；发版即生效。回滚：恢复 `Opacity` + `Text.rich` 行。

## Open Questions

- 无。竖线装饰若工期紧可在 tasks 中标为可选。

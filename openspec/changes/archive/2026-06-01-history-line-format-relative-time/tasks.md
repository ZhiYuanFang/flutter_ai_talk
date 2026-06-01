## 1. 数据与纯函数

- [x] 1.1 在 `history_mapper`（或并列 `history_line_format.dart`）中从 `Map`/`rawPayload` 解析 `eventNumber`、`startTime`、`endTime`（缺失/`0`/空 与「时间为 0」语义对齐），导出供 UI 使用的结构化字段或 `HistoryRecord` 扩展字段。
- [x] 1.2 实现 `formatHistoryInstant(DateTime t, DateTime nowLocal)`（或等价）覆盖「今日 / 昨天 / 今年 / 其它」四条分支；为单元测试注入 `now`。
- [x] 1.3 实现 `formatDurationForEvent0(DateTime start, DateTime end)`：满 1 小时展示「`H`小时`m`分钟」；不满 1 小时仅「`N`分钟」；不足 1 分钟（含 0 分钟）展示「不足 1 分钟」。

## 2. 文案分支与 Rich 模型

- [x] 2.1 实现 `buildHistoryLineSpans(...)`（或等价）按规格五条主模板输出 `InlineSpan` 列表或「时间前缀 + 事件名 + 尾部 + 可选备注」模型。
- [x] 2.2 `eventNumber == 0` 且 `endTime > 0` 分支拼出「`{格式化(endTime)}:{eventName}-> 用时{用时文案}`」字面顺序。
- [x] 2.3 为 `eventName` / `remark` 分别绑定 `TextStyle`（事件名相对 `bodyMedium` 加粗加大；备注缩小）；无备注不渲染占位。

## 3. UI 接入与回归

- [x] 3.1 首页历史 `ListView` 将单行 `Text` 替换为 `Text.rich`（或抽取 `HistoryLineTile` 组件），接入 2.1 产出。
- [x] 3.2 历史详情等其它展示 `HistoryRecord.displayLine` 的入口评估：改为复用同一 Rich 组件或保留纯文本回退策略（在设计允许范围内）。
- [x] 3.3 补充 `flutter_test`：相对时间四类 + `eventNumber` 各分支 + 用时满/不满 1 小时 + 备注空/非空。

## 4. 收尾

- [x] 4.1 `flutter analyze` 无新增告警；手动走查首页与绑定后列表在 WebSocket 增量下的样式不断行溢出（必要时 `maxLines`/`overflow`）。

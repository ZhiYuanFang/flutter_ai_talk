## Context

- 网关历史记录项已包含 `eventName`、`eventNumber`、`startTime`、`endTime`、`remark` 等字段；客户端当前在 `history_mapper` 中将 `action` 拼为「次数+单位+备注」的单一字符串，首页以单行 `Text` 展示。
- 产品要求按 `eventNumber` / 结束时间是否为零区分多种主文案模板，并对时间做「今天 / 昨天 / 今年 / 其它」的相对展示；事件名与备注需不同字重与字号。

## Goals / Non-Goals

**Goals:**

- 在单一能力边界内完成「展示模型 + 格式化 + 列表 UI」：从 `rawPayload` 可靠读出数值型 `eventNumber` 与时间戳，按规则生成分支文案。
- 相对时间与用时格式化可单元测试（纯函数 + 注入「当前日期」便于测今/昨/跨年）。
- 首页历史列表中事件名加粗加大、备注缩小；无备注分支不预留空白占位。

**Non-Goals:**

- 不修改网关接口契约与字段命名；不实现服务端排序或分页策略变更。
- 不在本变更中重做历史详情页整页信息架构（若详情沿用同一行组件则可复用）。

## Decisions

1. **展示数据模型**
  - 采用「结构化行模型」（例如 `HistoryLineSpan` / `TextSpan` 列表，或 `eventName` + `suffix` + `remark` 三段 + 样式枚举），由 `HistoryRecord` 计算属性或独立 `buildHistoryLine(record, now)` 产出；避免继续把备注硬塞进单一 `action` 字符串导致无法分别设样式。  
  - **备选**：保留 `displayLine` 单字符串 + `RichText` 用正则切分——**否决**：边界多、国际化与括号冲突风险高。
2. **「时间为 0」语义**
  - `endTime` / `startTime` 在 JSON 中缺失、`null`、空字符串、或解析为 epoch `0` 时，与产品所述「不存在就是 0」**等价**为未设置。  
  - **备选**：仅判 `null`——**否决**：与网关常见 `0` 占位不一致。
3. **相对时间锚点**
  - 使用设备本地时区；「今日 / 昨日 / 今年」以**自然日**对比本地日历日、本地日历年。展示格式在规格中固定为示例级（实现可用 `intl` 或手写补零）。
4. **用时展示（eventNumber = 0 且已结束）**
  - 整行字面顺序为「`{格式化(endTime)}:{eventName}-> 用时{时长文案}`」；`duration = endTime - startTime`（同一时区下的时间差）；`≥ 1 小时` 展示为「`H`小时`m`分钟」；`< 1 小时` **仅展示分钟**（如「`N`分钟」）；**时长不足 1 分钟（含 0 分钟）** 统一展示「**不足 1 分钟**」。
5. **样式**
  - 使用 `Text.rich` / `RichText` + `TextSpan`，在 `Theme` 上相对 `bodyMedium` 或 `titleSmall` 做 `fontWeight` / `fontSize` 倍率，避免硬编码绝对 px（除测试外）。

## Risks / Trade-offs

- **[Risk] 网关时间与类型不一致（字符串 vs 秒级 int）** → 在 `history_mapper` 统一解析为 `DateTime?` 与 `int`，非法回退为「0」语义并在开发环境 `debugPrint` 可选日志。  
- **[Risk] 规则 2 与规则 1 边界（`eventNumber` 恰好为 2）** → 规格明确 `> 1` 不含 `1`。  
- **[Risk] Rich 文本可访问性（语义标签）** → 保持整行一条语义节点或拆行一致策略，不在本变更引入复杂 Semantics 树（可记为后续改进）。

## Migration Plan

- 仅客户端发布；无数据迁移。回滚为恢复旧 `displayLine` 与单行 `Text`。

## Open Questions

- 规则 4 中 `{endTime}` 是否也需套用与规则 1 相同的相对时间格式——**默认是**（与全局时间规则一致）。  
- `remark` 为空时规则 1 是否省略括号——**默认省略**。


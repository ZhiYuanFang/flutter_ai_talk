## 1. 契约与仓库层

- [x] 1.1 与网关确认**删除**历史事件接口（HTTP 方法、path、body：`id`、`deviceNo` 等），并写入 README 或内部注释。
- [x] 1.2 在 `FeedRepository` / `RemoteFeedRepository` 增加 `deleteHistoryRecord`（或等价命名），实现错误与 Toast 行为与现有 `updateHistoryRecord` 一致。
- [x] 1.3 扩展 `updateHistoryRecord` 或新增参数对象：支持提交 `startTime`、`endTime`、`remark`、`eventNumber`（用量）、`eventUnit`（若需要）的可选组合；更新 `buildEventUpdateBody` 以合并「仅变更字段 + 原始 payload」。

## 2. 历史详情 UI

- [x] 2.1 将事件名、主动作/摘要改为只读展示；新增或保留独立「备注」可编辑框并绑定 `remark`。
- [x] 2.2 按 `rawPayload` 中 `eventNumber` 分支渲染：`0` 显示开始/结束时间选择；`1` 与 `>1` 仅显示结束时间选择；`>1` 额外显示用量数值输入（及单位只读展示，若有）。
- [x] 2.3 增加删除按钮与二次确认对话框；成功后 `pop(true)` 并处理失败态。

## 3. 校验与联调

- [x] 3.1 保存前校验：备注非空规则按产品调整（若允许空备注则放宽）；时间先后关系（结束不早于开始等）在客户端做基础校验或与后台错误提示配合。
- [x] 3.2 手动验证：`eventNumber` 为 0/1/>1 三类记录的保存与删除；`1`/`>1` 仅改结束时间后在列表/详情中与后台「开始=结束」一致。

## 4. 收尾

- [x] 4.1 `flutter analyze` 通过；必要时为 `buildEventUpdateBody` 补充轻量单元测试（字段合并）。

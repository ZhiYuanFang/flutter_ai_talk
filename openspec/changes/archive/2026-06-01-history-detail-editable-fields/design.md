## Context

- 现状：`HistoryDetailScreen` 使用两个 `TextFormField` 编辑事件名与「动作」，保存时 `buildEventUpdateBody` 将「动作」写入 `remark`，并提交 `eventName`。
- 目标：删除、只读约束、按 `eventNumber` 开放时间与用量编辑；部分行为依赖**服务端**在 `eventNumber >= 1` 且仅改结束时间时自动把 `startTime` 设为与 `endTime` 相同。

## Goals / Non-Goals

**Goals:**

- 表单与校验与 `rawPayload.eventNumber` 分支一致；保存时请求体仅包含允许变更的字段（其余沿用原 payload 或后台忽略策略与网关约定）。
- 删除成功后关闭详情并通知列表刷新（与现有 `context.pop(true)` 模式一致）。

**Non-Goals:**

- 不在本变更中重做首页历史行展示规则（由既有 `history-line-format` 能力覆盖）。
- 不定义服务端「自动改开始时间」的算法细节，仅依赖接口契约说明。

## Decisions

1. **只读展示**  
   - 事件名：只读 `Text` 或禁用输入框。  
   - 「动作」：若产品所指为列表上的「主文案/动作摘要」，则以只读 `Text` 展示（可用 `historyLinePlainText` 或网关返回的固定字段）；**不得**再映射到可编辑的 `TextFormField`。备注单独 `TextFormField` 绑定 `remark`。

2. **时间编辑控件**  
   - 默认入口：**先调时分**（`showTimePicker`，`TimePickerEntryMode.input` 便于直接改分、再改时），**保留当前日期**；单独提供 **「改日期」**（仅 `showDatePicker`，保留已选时分）。  
   - 写入 `POST /device/history/api/event/update` 时，`startTime` / `endTime` MUST 为 **Unix 秒级整型时间戳**（与列表/详情解析一致），**不得**使用毫秒时间戳或 `yyyy-MM-dd HH:mm:ss` 字符串。清除结束时间时 `endTime` 为 `0`。

3. **用量（`eventNumber > 1`）**  
   - UI 提供数值（及可选 `eventUnit` 若 payload 已有）；提交时写回 `eventNumber`（及 `eventUnit` 不变或可编辑——默认仅开放数值，单位只读除非网关要求）。

4. **删除接口**  
   - 网关约定：`POST /device/history/api/event/delete`，JSON body 字段 **`id`**（整型）、**`deviceNo`**（字符串）。`FeedRepository.deleteHistoryRecord` 使用当前会话下的 `deviceNoGetter` 填充 `deviceNo`。

5. **`eventNumber == 0` 未结束（仅开始）**  
   - 若 `endTime` 语义为未设置，UI 仅展示/编辑开始时间，结束时间可选空；与列表行「开始计时」语义一致，保存逻辑不强行写 `endTime`。

## Risks / Trade-offs

- **[Risk] 删除接口未在仓库文档中出现** → 实现前与后端确认路径与字段；可先合并 UI + mock 开关。  
- **[Risk] 后台「开始=结束」与客户端本地校验冲突** → 保存后以服务端回包或再次拉取为准，Toast 提示。

## Migration Plan

- 纯客户端行为变更 + 可选新 API；无本地数据迁移。

## Open Questions

- （已确认）删除接口：`POST /device/history/api/event/delete`，入参 `id`、`deviceNo`。

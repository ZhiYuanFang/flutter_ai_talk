## Why

历史详情页目前允许编辑事件名与「动作」，与业务规则不符：用户需要按记录类型（`eventNumber`）差异化编辑开始/结束时间、用量与备注，并支持删除单条事件；事件名与主动作类信息应保持只读，避免误改核心语义。

## What Changes

- 历史详情提供**删除当前事件**能力（需网关删除接口；若路径未定，在实现阶段与网关对齐后落地）。
- **事件名**与**动作**（或与其等价的只读主展示）改为只读，**不得**再通过表单直接提交修改。
- **备注**（`remark`）可编辑并随更新请求提交。
- 当 `eventNumber == 0`：允许编辑**开始时间**与**结束时间**。
- 当 `eventNumber == 1`：仅允许编辑**结束时间**；客户端提交后由**后台**将开始时间自动调整为与结束时间一致（客户端不强制写 start，但规格需写明依赖后台行为）。
- 当 `eventNumber > 1`：允许编辑**结束时间**（同上，后台同步开始时间）；并允许编辑**用量**（与网关字段对齐，通常为 `eventNumber` 数值与/或 `eventUnit`，以设计为准）。

## Capabilities

### New Capabilities

- `history-detail-screen`：历史详情页的删除、只读字段、按 `eventNumber` 的可编辑字段与保存/校验语义，以及与网关更新/删除契约的对应关系。

### Modified Capabilities

- （仓库根目录 `openspec/specs` 当前无基线目录；不声明 MODIFIED 基线能力。）

## Impact

- Flutter：`HistoryDetailScreen`、`FeedRepository` / `RemoteFeedRepository`、`buildEventUpdateBody`（`history_mapper.dart`）、路由返回（删除成功后 `pop` 等）。
- 网关：历史事件 **update** 请求体字段扩展；新增或确认 **delete** 接口路径与幂等语义。

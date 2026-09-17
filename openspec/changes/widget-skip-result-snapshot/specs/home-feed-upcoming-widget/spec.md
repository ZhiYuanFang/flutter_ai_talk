## ADDED Requirements

### Requirement: Foreground widget sync SHALL persist a prediction result snapshot for background skip

When the client successfully pushes a ready home-widget payload from the foreground sync path (after computing predictions with the same inputs as the smart prediction page), the client MUST also persist a prediction-result snapshot that is readable from the home_widget background interactivity isolate. The snapshot MUST contain an ordered list of prediction rows sufficient to rebuild hero and `recentLast` for the large layout budget (at least six subsequent-attention slots plus a hero candidate). On logout or when pushing an empty widget payload for the signed-out user, the client MUST clear or replace the snapshot so a previous user’s predictions are not reused.

当前台成功推送 ready 小组件 payload 时，客户端 **必须** 额外持久化一份后台交互 isolate 可读的预测结果快照；快照 **必须** 含足以重建 large 预算（hero + 至少 6 条后续留意）的有序预测行。登出或推送未登录 empty payload 时 **必须** 清除或覆盖快照。

#### Scenario: sync ready 后写出快照

- **WHEN** 已登录用户完成一次前台 `scheduleHomeWidgetSync`（或等价）且 payload `state` 为 `ready` 并成功 `pushHomeWidgetPayload`
- **THEN** 客户端 MUST 写入非空预测结果快照（含有序 `eventId` 与重建所需时间字段）
- **AND** 该快照 MUST 可被随后的后台 skip 回调读取（无需 Riverpod）

#### Scenario: 登出清除快照

- **WHEN** 用户登出并写入 empty 小组件 payload
- **THEN** 预测结果快照 MUST 被清除或替换为空，不得继续提供上一用户的预测行

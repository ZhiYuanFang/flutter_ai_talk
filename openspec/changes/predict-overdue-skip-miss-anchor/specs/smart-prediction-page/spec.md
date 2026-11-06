## ADDED Requirements

### Requirement: Overdue non-appointment cards SHALL offer skip-this-prediction

When a hot (non-demo) smart prediction card for a **non-appointment** root shows a computable prediction whose `nextAt` is overdue, the client MUST present a「跳过本次」control (or equivalent). Activating it MUST persist that card’s current `nextAt` as the root’s `missAnchor` and MUST trigger a refresh of local prediction so the card shows the re-predicted next occurrence per `event-interval-prediction`. One activation MUST advance only one miss step (set `missAnchor` to the then-current `nextAt` once). The client MUST NOT show the control when not overdue, when there is no prediction, for appointment roots, for demo-skeleton cards, or when forecast is OFF. The control MUST NOT write feeding history and MUST NOT use `WidgetHeroSkipStore` / hero-skip semantics. When a new real occurrence tip for that root is at or after the persisted `missAnchor`, the client MUST clear `missAnchor` so subsequent prediction anchors on the true `lastAt` again.

热态非骨架、**非预约**预测卡在可计算预测且 `nextAt` 已逾期时，MUST 展示「跳过本次」（或等价）控件。激活后 MUST 将当时 `nextAt` 持久化为该根 `missAnchor`，并 MUST 刷新本地预测以展示按 `event-interval-prediction` 重算的结果。一次激活 MUST 只推进一档。未逾期、无预测、预约、骨架、推演关闭时 MUST NOT 展示。MUST NOT 写喂养历史，MUST NOT 走 hero-skip。该根新真发生 tip ≥ `missAnchor` 时 MUST 清除 `missAnchor`。

#### Scenario: 逾期显示跳过

- **WHEN** 非预约热态卡有逾期 `nextAt`
- **THEN** 卡上 MUST 展示「跳过本次」

#### Scenario: 跳过写入 missAnchor 并刷新

- **WHEN** 用户激活「跳过本次」且当时 `nextAt=N`
- **THEN** 本机 MUST 持久化该根 `missAnchor=N`
- **AND** 预测刷新后卡上 MUST 展示按错过点重算的新 `nextAt`（若可算）
- **AND** MUST NOT 新增喂养历史记录

#### Scenario: 未逾期不展示

- **WHEN** 非预约热态卡 `nextAt` 仍在未来
- **THEN** MUST NOT 展示「跳过本次」

#### Scenario: 真发生清除 missAnchor

- **WHEN** 该根写入或合并真发生且 tip ≥ 已存 `missAnchor`
- **THEN** 客户端 MUST 清除该根 `missAnchor`

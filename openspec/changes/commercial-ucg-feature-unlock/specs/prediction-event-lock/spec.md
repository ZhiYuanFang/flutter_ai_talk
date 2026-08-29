## ADDED Requirements

### Requirement: Prediction event locks SHALL unlock first allowedCount real rows in display order

On the smart prediction page, the client MUST keep rendering full real prediction event cards. Locked events MUST show `FeatureLockOverlay`（文案「点击开通」）. Unlocking MUST be driven only by the integer `allowedCount` on the catalog item whose `featureId` is `prediction_unlock` (default 0 if missing): taking `smartPredictionRowsProvider` display order, skipping demo/skeleton rows, the first `allowedCount` real rows MUST appear without lock overlay; remaining real rows MUST stay locked. The client MUST NOT require a server list of event IDs. When `isVip` is true, the client MUST unlock all real prediction rows. When `allowedCount` is `-1` (server full-access sentinel), the client MUST unlock all real prediction rows without requiring `isVip`. Tapping a locked overlay MUST navigate to the feature unlock hub.

智能预测页 **必须** 保留完整真实事件展示；锁定行 **必须** 叠 FeatureLockOverlay。解锁 **仅** 由 catalog 中 `prediction_unlock.allowedCount` 决定：按展示顺序跳过骨架后前 N 条无锁；**`allowedCount == -1`（服务端临时/永久全开哨兵）必须全开真实行**。`isVip` 时 **必须** 全部解锁。点击锁定 **必须** 进入开通中心。

#### Scenario: 按数量解锁前 N 条

- **WHEN** `isVip` 为 false 且 `prediction_unlock.allowedCount` 为 2，且真实预测行至少 3 条
- **THEN** 展示顺序中前 2 条真实行 MUST 无锁定浮层
- **AND** 其后真实行 MUST 显示锁定浮层

#### Scenario: 哨兵 -1 全开

- **WHEN** `isVip` 为 false 且 `prediction_unlock.allowedCount` 为 `-1`
- **THEN** 所有真实预测行 MUST NOT 显示锁定浮层

#### Scenario: VIP 全解锁

- **WHEN** `isVip` 为 true
- **THEN** 所有真实预测行 MUST NOT 显示锁定浮层（与 `allowedCount` 无关）

#### Scenario: 骨架行不计入名额

- **WHEN** 页面处于 demo/skeleton 展示路径
- **THEN** 骨架行 MUST NOT 消耗 `allowedCount` 名额

#### Scenario: 点击锁定进开通中心

- **WHEN** 用户点击某条锁定预测卡的「点击开通」浮层
- **THEN** 客户端 MUST 导航至开通中心页

#### Scenario: allowedCount 来自 catalog

- **WHEN** 客户端已成功拉取 feature/catalog
- **THEN** 预测锁所用 `allowedCount` MUST 取自 `featureId=prediction_unlock` 项（缺失则按 0）
- **AND** MUST NOT 依赖独立 allowed-count HTTP 路径

#### Scenario: 冷启落在预测页须 ensure catalog

- **WHEN** 用户冷启且主壳初始页为预测页（`onPageChanged` 未触发）
- **THEN** 客户端 MUST 在首帧可见时 ensure 加载 feature/catalog
- **AND** MUST NOT 仅依赖滑入预测页才拉取，以免 `allowedCount` 默认为 0 导致真实事件卡全锁

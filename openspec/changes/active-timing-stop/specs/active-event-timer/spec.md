## ADDED Requirements

### Requirement: 进行中计时判定

The system SHALL treat a history record as an active timing session when `eventNumber == 0` and end time is unset per `historyInstantUnset`. 系统必须把 `eventNumber == 0` 且结束时间按 `historyInstantUnset` 判定为未设置的历史记录视为**进行中计时**；开始时刻为 `startTime`（缺失时用 `createdAt`），与列表/详情既有解析一致。

#### Scenario: 未结束的计时记录

- **WHEN** 记录的 `eventNumber` 为 0 且 `endTime` 未设置
- **THEN** 系统必须将该记录标记为进行中，并启用实时时长与停止能力

#### Scenario: 已结束的计时记录

- **WHEN** 记录的 `eventNumber` 为 0 且 `endTime` 已有效
- **THEN** 系统不得将其视为进行中，不得展示实时 tick 或停止按钮

### Requirement: 进行中已计时长格式

The system SHALL format elapsed active timing as `MM:SS` when under one hour and as `HH:MM:SS` when one hour or more. 系统必须把进行中已计时长格式化为：不足 1 小时为 **`MM:SS`**（分、秒均两位、零填充，如 `05:23`）；满 1 小时及以上为 **`HH:MM:SS`**（时、分、秒均两位、零填充，如 `01:12:05`）。计算基准为当前时刻与开始时刻之差，每秒更新。

#### Scenario: 不足一小时

- **WHEN** 进行中记录已过去 5 分 23 秒
- **THEN** 展示必须为 `05:23`

#### Scenario: 满一小时及以上

- **WHEN** 进行中记录已过去 1 小时 12 分 5 秒
- **THEN** 展示必须为 `01:12:05`

### Requirement: 直接停止进行中计时

The system SHALL end an active timing session by updating the record with `endTime` set to the current time via the existing history update API, without a confirmation dialog. 系统必须通过既有历史更新接口（`updateHistoryRecord` / `POST /device/history/api/event/update`）将 `endTime` 设为当前时间以结束进行中计时；**不得**弹出二次确认。必须保留原 `remark` 与 `startTime`（除非网关另有约定）。

#### Scenario: 用户点击停止

- **WHEN** 用户在主页历史行或详情预览点击「停止」且请求成功
- **THEN** 该记录必须变为已结束状态，UI 停止每秒刷新，并展示与既有规则一致的已结束文案

#### Scenario: 停止请求失败

- **WHEN** 停止请求被网关拒绝或网络失败
- **THEN** 系统必须保持进行中状态与实时展示，并向用户提示错误（与现有仓库 Toast 一致）

### Requirement: 存在进行中时每秒刷新

The system MUST refresh active timing displays at least once per second while any active timing record is visible on the current screen. 当当前屏幕存在至少一条进行中计时记录时，系统必须至少每秒刷新一次相关 UI（主页历史列表或详情预览）；无进行中记录时不得维持周期性刷新定时器。

#### Scenario: 主页存在进行中

- **WHEN** 主页历史列表包含一条或多条进行中记录且页面处于前台
- **THEN** 各行已计时长必须每秒更新

#### Scenario: 详情预览进行中

- **WHEN** 用户在详情预览模式打开一条进行中记录
- **THEN** 已计时长必须每秒更新直至结束或离开页面

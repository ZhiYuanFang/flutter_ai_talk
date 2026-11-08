## ADDED Requirements

### Requirement: Appointment last-occurrence SHALL use unbounded history filter

For appointment roots on the smart prediction waterfall/compact card, when showing the last-occurrence row, the client MUST obtain the latest real history record via `GET /device/history/api/filter` with root-and-descendant `eventIds`, `limit=1`, and `ignoreTimeRange` true (or equivalent that applies no start/end window). The client MUST display that record’s occurrence time and, when `remark` is non-empty, append ` · {remark}`. The client MUST NOT rely solely on the prediction seven-day range window for this row, MUST NOT invent remark text, and MUST NOT use `GET /device/history/api/event/latest` (device-global latest). 预约卡「上一次」MUST 经不限窗 filter 取最近一条并展示时间与非空备注；MUST NOT 仅靠近 7 日窗；MUST NOT 使用整机 event/latest。

#### Scenario: Old appointment still shows last row

- **WHEN** 某预约根最近一次 history 早于预测近 7 日窗且 filter 返回该条（含 remark）
- **THEN** 瀑布预约卡上次发生行 MUST 展示该时间，且非空 remark MUST 以 ` · ` 追加

#### Scenario: Filter wires ignoreTimeRange

- **WHEN** 客户端为预约上次发生发起 filter
- **THEN** 请求 MUST 带上使时间窗被忽略的参数（如 `ignoreTimeRange=true`）与该根（及子）`eventIds`、`limit=1`

### Requirement: Appointment next sheet SHALL lift remark and collapse wheels on keyboard

When the dedicated next-appointment sheet’s remark field is focused or the soft keyboard is visible, the client MUST collapse/hide the datetime wheel columns so the remark field remains visible, and MUST apply the same family of keyboard avoidance used by the unified event-record create sheet (`respectKeyboardInset` and remark `keyboardLift` / equivalent). When the remark field loses focus and the keyboard is dismissed, the client MUST restore the datetime wheels. 预约下次 sheet 在备注获焦或键盘可见时 MUST 收起时间滚轮并避让键盘；失焦且键盘收起后 MUST 恢复滚轮。

#### Scenario: Focus remark collapses wheels

- **WHEN** 用户聚焦预约 sheet 备注输入框导致键盘弹出
- **THEN** 四列时间滚轮 MUST 收起或不可见，且备注输入框 MUST 不被键盘遮挡

#### Scenario: Dismiss keyboard restores wheels

- **WHEN** 用户收起键盘且备注失焦
- **THEN** 时间滚轮 MUST 恢复可滚动选择

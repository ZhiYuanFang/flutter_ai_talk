## ADDED Requirements

### Requirement: Ordinary add for time one and number SHALL open the unified record sheet

When intent is `EventRecordIntent.add` and the target leaf `eventType` is `time`, `one`, or `number`, the client MUST open the unified event-record create sheet and MUST NOT submit an occurrence until the user confirms in that sheet (cancel MUST NOT write). This MUST apply to feeding-home grid taps, catalog multi-level picker selections, and smart-prediction card taps (direct leaf or after picker). For `time`, if that event is already actively timing, the client MUST show the existing in-progress toast and MUST NOT open a duplicate timing sheet. 普通新增 `time`/`one`/`number` MUST 先开统一记录 sheet；覆盖喂养格、多级选叶、预测直点与深入；`time` 已在计时 MUST toast 且 MUST NOT 再开 sheet。

#### Scenario: Home one opens sheet

- **WHEN** 用户在喂养页点击 `eventType=one` 叶子发起 add
- **THEN** 客户端 MUST 打开统一记录 sheet，MUST NOT 立即以 now 落库

#### Scenario: Home time opens sheet

- **WHEN** 用户在喂养页点击 `eventType=time` 叶子发起 add 且未在计时中
- **THEN** 客户端 MUST 打开统一记录 sheet，MUST NOT 立即以 endTime=0 开计时落库

#### Scenario: Picker then one opens sheet

- **WHEN** 用户经目录多级选择选中 `one` 叶子后继续 add
- **THEN** 客户端 MUST 打开统一记录 sheet，MUST NOT 立即落库

#### Scenario: Prediction time opens sheet without confirm dialog

- **WHEN** 用户在预测页对 `time` 叶子发起普通 add（直点或深入后）
- **THEN** 客户端 MUST 直接打开统一记录 sheet，MUST NOT 展示「确认添加」玻璃确认框

## MODIFIED Requirements

### Requirement: Prediction confirm-add dialog SHALL remain for non-quantity add only

When the prediction page (or any surface) invokes add with intent `add` and type is `time` or `one`, the client MUST open the unified create record sheet and MUST NOT show the「确认添加」glass confirm dialog and MUST NOT immediately submit a now occurrence. When intent is `supplement`, the client MUST continue to open the unified sheet and MUST NOT show that confirm dialog. 任意入口普通新增 `time`/`one` MUST 开统一 sheet；MUST NOT「确认添加」后即时 now；补充路径仍直接 sheet 且 MUST NOT 先弹确认框。

#### Scenario: Prediction time or one opens sheet

- **WHEN** 预测卡触发 add 且事件为 time/one 叶子
- **THEN** 客户端 MUST 打开统一记录 sheet，MUST NOT 先展示「确认添加」再提交 now

#### Scenario: Supplement still sheet without confirm

- **WHEN** 用户对 `time`/`one` 走补充意图
- **THEN** 客户端 MUST 直接打开统一 Sheet 且 MUST NOT 先弹「确认添加」

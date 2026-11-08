## MODIFIED Requirements

### Requirement: Client MUST present supplement-next only on non-list appointment surfaces

For appointment events on the smart prediction surface, the client MUST NOT present the per-card 「补充大概多久一次」 flow. The client MUST present 「补充下次」 (or equivalent) that opens the dedicated next-appointment sheet on **waterfall/compact** (and landscape compact) appointment cards. The vertical list MUST NOT show appointment root cards at all (including when nextAt is 0), so list MUST NOT be the host for「补充下次」. Cards with no stored nextAt MUST still be shown on waterfall/compact when other prediction-card rules allow, without emitting a pushable pending node. 预约「补充下次」MUST 在瀑布/compact；竖列表 MUST NOT 展示预约根；无约定卡在瀑布仍可展示且 MUST NOT 产生可推送节点。

#### Scenario: Supplement next on waterfall

- **WHEN** 用户在瀑布预约卡上发起「补充下次」
- **THEN** 客户端 MUST 打开专用下一次预约 sheet，MUST NOT 打开间隔 picker

#### Scenario: No appointment card on vertical list

- **WHEN** 预约根 nextAt=0 且布局为竖列表
- **THEN** 该根 MUST NOT 出现在竖列表

### Requirement: Client MUST sync appointment nextAt and remark via dedicated API

The client MUST read and write next trigger time **and remark** through `GET`/`PUT /device/app/api/appointment/next` with `deviceNo`, root `eventId`, `nextAt`, and `remark`, independent of history CRUD. `nextAt=0` MUST mean no appointment (and MUST clear remark per twin). Editing any history row of the same root MUST show the same nextAt/remark. 客户端 MUST 经预约 API 读写 nextAt 与 remark；与 history 解耦；`nextAt=0` MUST 无约定（备注按 twin 清空）。

#### Scenario: GET returns remark

- **WHEN** 客户端 GET 某根预约 next 且服务端存有备注
- **THEN** 响应 MUST 含非空 `remark` 供 sheet/卡展示

#### Scenario: PUT writes remark with nextAt

- **WHEN** 用户在专用 sheet 确认正 nextAt 与备注
- **THEN** 客户端 MUST PUT 含该 `nextAt` 与 `remark` 并触发 pending 同步

## ADDED Requirements

### Requirement: Appointment card copy and logo SHALL use appointment semantics

On waterfall/compact appointment cards, user-visible captions that would otherwise say 预测/预计 for non-appointment cards MUST use 预约 wording instead (e.g. toggle / clock-mode / countdown family). When forecast is enabled and a countdown is shown, the event logo MUST remain inline to the left of the event name and MUST NOT use the large centered hero logo above the countdown. 预约卡文案 MUST 用「预约」语义；推演开时 logo MUST 在标题左侧，MUST NOT 居中放大。

#### Scenario: Copy uses 预约

- **WHEN** 瀑布展示预约热态卡
- **THEN** 倒计时/开关相关可见文案 MUST 使用预约用语，MUST NOT 使用「预测」「预计」作为该卡主文案

#### Scenario: Logo stays leading

- **WHEN** 预约卡推演开启且展示 countdown
- **THEN** logo MUST 在事件名左侧，MUST NOT 在倒计时上方居中大图

### Requirement: Appointment last-occurrence row SHALL include latest history remark

When an appointment card shows the last-occurrence row, the client MUST show the time of the latest real history record under that root and, when that record’s `remark` is non-empty, append ` · {remark}`. The remark MUST come from history (latest record), not from appointment-next remark. 预约卡上次发生 MUST 为最新 history 时间，非空 remark MUST 以 ` · {备注}` 追加。

#### Scenario: Last row with remark

- **WHEN** 预约根最新 history 含非空 remark
- **THEN** 上次发生行 MUST 展示时间与 ` · ` 加该 remark

### Requirement: Next-appointment sheet SHALL edit remark and default previous appointment remark

The dedicated next-appointment sheet MUST allow editing the appointment `remark` together with the datetime wheels. Confirm MUST PUT both `nextAt` and `remark`. When opening the sheet for create/edit, the remark field MUST default to the previously stored appointment-next `remark` from GET (empty if none). Card chrome that shows the next appointment instant MUST append ` · {remark}` when remark is non-empty. 专用 sheet MUST 可编辑备注并与 nextAt 一并 PUT；打开时 MUST 默认回填上次预约备注；卡上时刻后可跟下次备注。

#### Scenario: Default previous remark

- **WHEN** 用户打开改约 sheet 且 GET 返回 remark=R
- **THEN** 备注输入 MUST 默认填入 R

#### Scenario: Card shows next remark

- **WHEN** 热态预约卡有未来 nextAt 且 remark 非空
- **THEN** 预约时刻文案后 MUST 追加 ` · ` 与该 remark

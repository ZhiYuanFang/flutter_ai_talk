## MODIFIED Requirements

### Requirement: Appointment last-occurrence SHALL use unbounded history filter

For appointment roots on the smart prediction waterfall/compact card, when showing the last-occurrence row, the client MUST resolve display time and remark from the **appointment-last local cache** (memory hydrated from disk when available). The client MUST NOT use the shared history pool as the primary display source for appointment last-occurrence. The client MUST still obtain or refresh the latest real history record via `GET /device/history/api/filter` with root-and-descendant `eventIds`, `limit=1`, and `ignoreTimeRange` true (or equivalent) as a **silent** path that updates the appointment-last cache (memory and disk); this refresh MUST NOT be skipped solely because memory already holds a last. The client MUST display that cached record’s occurrence time and, when `remark` is non-empty, append ` · {remark}`. The client MUST NOT invent remark text, MUST NOT use `GET /device/history/api/event/latest` (device-global latest), and MUST NOT read `appointment_next` as last occurrence. Cold start / enter prediction / resume / pull MUST hydrate or keep cache visible before requiring network success.

预约卡「上一次」MUST 只认预约 last 本地缓存先展示；MUST 以不限窗 filter 静默刷新并写回；MUST NOT 以统一历史池为展示主源；MUST NOT 用 nextAt 当 last；MUST NOT 使用整机 event/latest。

#### Scenario: Cache shows without waiting network

- **WHEN** 预约 last 磁盘或内存已有该根快照（含时间与可选 remark）
- **THEN** 瀑布预约卡上次发生行 MUST 可展示该缓存时间（及非空 remark）
- **AND** 客户端 MAY 并行静默不限窗 filter 写回

#### Scenario: Silent filter updates cache

- **WHEN** 静默 ignoreTimeRange filter 成功返回该根最近一条
- **THEN** 客户端 MUST 更新预约 last 内存与磁盘缓存
- **AND** 卡面 MUST 反映写回后的时间/备注

#### Scenario: Filter wires ignoreTimeRange

- **WHEN** 客户端为预约上次发生发起 filter
- **THEN** 请求 MUST 带上使时间窗被忽略的参数（如 `ignoreTimeRange=true`）与该根（及子）`eventIds`、`limit=1`

#### Scenario: Pool is not appointment last primary

- **WHEN** 统一历史池对该预约根有近窗记录，但预约 last 缓存尚未 hydrate
- **THEN** 客户端 MUST NOT 仅因池内有记录而把池时刻当作预约「上一次」主源（须等缓存或静默写回）

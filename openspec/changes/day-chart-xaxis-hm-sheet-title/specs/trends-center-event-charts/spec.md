## MODIFIED Requirements

### Requirement: Selected-day detail chart by event type

The selected-day detail region SHALL show a sparse bar chart for `time`/`number` events (one bar per positive sample): each bar’s local `HH:mm` SHALL appear on the **X axis**, and each bar’s metric value SHALL appear as a **bar-top** label (using the same metric formatting as other trend charts). The client MUST NOT use bar-top labels primarily for the clock time. Count (`one`) events SHALL keep the count-day timeline (`trends-count-day-timeline`).

某日详图：`time`/`number` MUST 展示**稀疏柱图**（仅有有效样本处出柱；每柱本地时刻 **`HH:mm` MUST 在 X 轴**；每柱**量值 MUST 在柱顶**；X 轴 MUST NOT 强制 24 整点桶；柱顶 MUST NOT 再作为主时刻展示）；`one` MUST 展示计次时间轴。

#### Scenario: Timing or quantity day bars

- **WHEN** 选中计时或计数（量）事件且选中日有至少一条有效样本
- **THEN** 某日详图 MUST 为柱图，柱数 MUST 等于有效样本数，每柱在 **X 轴** MUST 可见精确到分的时间，且柱顶 MUST 可见该样本量值文案

#### Scenario: Count-once day timeline

- **WHEN** 选中计次事件且选中日有数据
- **THEN** 某日详图 MUST 为时间轴图（非折线、非量/时柱图）

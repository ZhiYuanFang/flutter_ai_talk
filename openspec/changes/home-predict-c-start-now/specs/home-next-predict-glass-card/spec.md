## RENAMED Requirements

- FROM: `Glass card CTA SHALL start event add like the matching event button with C-only predicted start`
- TO: `Glass card CTA SHALL start event add like the matching event button with C-only forced sheet`

## MODIFIED Requirements

### Requirement: Glass card CTA SHALL start event add like the matching event button with C-only forced sheet

Activating the trailing CTA MUST start the same feeding-home add pipeline as tapping the corresponding bucket event button (`handleEventGridTap` semantics: leaf picker when tapping a root with children, remote gates, active-timing toast). For states A and B, the start instant MUST be approximately now, and `time` + `EventRecordIntent.add` on feeding home MAY use direct timing add (skip sheet). For state C only, the client MUST open the unified create record sheet with the start control initialized to approximately now (MUST NOT prefill the prediction `nextAt`), and MUST NOT use feeding-home direct timing add even when the event type is `time`. States A and B MUST NOT prefill `nextAt` as the sheet start when a sheet is shown.

激活右侧 CTA MUST 走与点对应桶事件按钮相同的喂养页新增链路（根带孩子时可出叶子选择器、远程闸门、已在计时 toast）。A/B 的开始时刻 MUST 约为当前时刻，且喂养页上 `time`+`add` MAY 直开计时（跳过 sheet）。**仅 C** MUST 打开统一创建记录 sheet，并将开始时间控件初始化为约等于当下（MUST NOT 预填预测 `nextAt`），即使事件类型为 `time` 也 MUST NOT 走喂养页直开计时。A/B 在需要打开 sheet 时 MUST NOT 把开始时间预填为 `nextAt`。

#### Scenario: A or B time CTA may direct-start with now

- **WHEN** the card is in state A or B and the bucket event type is `time` and no active timing blocks add
- **THEN** activating the CTA MAY start timing immediately with start ≈ now without the create sheet

#### Scenario: C always sheets with start approximately now

- **WHEN** the card is in state C and the user activates `补记`
- **THEN** the unified create sheet opens
- **AND** the start time control is initialized to approximately now, not the prediction `nextAt`
- **AND** direct timing add on home MUST NOT run for that activation

#### Scenario: Non-time A/B sheet uses now

- **WHEN** the card is in state A or B and add opens the create sheet (non-`time` or non-direct path)
- **THEN** the start time control is initialized to approximately now, not `nextAt`

#### Scenario: Merge root with children still opens leaf picker

- **WHEN** the CTA targets a merge-predict root that has children
- **THEN** the client MAY show the catalog leaf picker before add, same as tapping that root event button

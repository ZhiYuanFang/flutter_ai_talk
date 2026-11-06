## ADDED Requirements

### Requirement: 跨夜记录左列 MUST 与 start 日键一致

When a finished timing record’s `startTime` and `endTime` fall on different local calendar days, the day section that contains the row SHALL remain keyed by `startTime`, and the row’s left-column `HH:mm` SHALL display the start time-of-day on that same start day. 跨夜已结束计时 MUST 仍按 `startTime` 归日；该行左列 `HH:mm` MUST 为开始时分，与该日块一致，MUST NOT 因 `endTime` 落在次日而把左列改成结束时分。

#### Scenario: 昨夜入睡今早醒来

- **WHEN** `eventNumber == 0` 且已结束，`startTime` 本地昨天 22:10，`endTime` 本地今天 07:05
- **THEN** 该记录 MUST 出现在「昨天」（或对应）日块下，且左列 MUST 为 `22:10`

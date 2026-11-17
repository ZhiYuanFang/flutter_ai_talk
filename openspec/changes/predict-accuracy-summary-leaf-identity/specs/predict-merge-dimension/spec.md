## ADDED Requirements

### Requirement: Merge-root accuracy day summary MUST NOT attribute rows to child leaves

When rendering the vertical-list accuracy day summary for a root with `mergePredict=true`, the client MUST treat summary rows as root-scoped对照 and MUST NOT label those rows with child event logo or child event name, even when underlying history records use child `eventId`s. Non-merge roots remain governed by `predict-list-accuracy-bars` leaf-identity summary rules.

合并根准确率当日小结 MUST NOT 用子 logo/名标注行；底层历史即使挂在叶子亦同。

#### Scenario: Merge feeding summary anonymous leaves

- **WHEN** 合并喂养根小结列出多条预计→实际
- **THEN** 各行 MUST NOT 出现配方奶/母乳等子事件名或子 logo

## ADDED Requirements

### Requirement: Accuracy day summary SHALL show leaf identity only for non-merge roots

When the user opens an in-card accuracy day summary for a smart-prediction vertical-list card whose catalog root has `mergePredict=false` and has children, each real (non-sample) summary row that corresponds to a history occurrence MUST show that occurrence’s leaf event logo and leaf event name, and the leaf name text color MUST follow that leaf’s brand/accent color. The existing预计 vs 实际 detail MUST remain visible on the row. Sample/example summary rows MAY omit leaf chrome or use documented sample styling.

When the card’s catalog root has `mergePredict=true`, summary rows MUST NOT show leaf logo or leaf event name (merge summary MUST NOT follow leaves). Roots with no children keep text-only预计→实际 rows.

点柱当日小结：非合并有子时每行 MUST 含子 logo 与子名（名色跟子）；合并根 MUST NOT 展示叶子身份。

#### Scenario: Non-merge summary shows two children

- **WHEN** 营养品类非合并根当日有 AD 与 3D 各至少一条合格样本并进入小结
- **THEN** 小结 MUST 分别出现带 AD logo/名与 3D logo/名的行（名色跟各自子色）

#### Scenario: Merge summary has no leaf chrome

- **WHEN** 喂养类合并根当日有多条子历史合格样本并进入小结
- **THEN** 小结行 MUST 展示预计→实际（或等价）且 MUST NOT 展示叶子 logo 或叶子事件名

#### Scenario: Card header still root-branded

- **WHEN** 非合并根准确率对照卡打开小结
- **THEN** 卡头 logo/名/accent MUST 仍跟目录根（本需求仅约束小结行）

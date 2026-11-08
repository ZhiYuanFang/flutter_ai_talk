## MODIFIED Requirements

### Requirement: Lock screen SHALL show a centered theme-colored brand row and dynamic item rows

The lock-screen Live Activity MUST vertically stack one row per ContentState item, using the existing Imminent row chrome for `kind=imminent` and the existing Timing row chrome for `kind=timing` (logo from local `eventId` visuals, titles, expect trailing / expectEndAt subtitle / elapsed timer semantics unchanged). The client MUST NOT render a top brand / App-name row such as「胖宝」(centered or otherwise) inside the Live Activity content, so that vertical space is reserved for item rows. The client MUST NOT invent a fixed three-row template independent of `items`. The client MUST NOT restore nextAt-based countdown copy on Imminent rows. 锁屏 MUST 仅按 `items` 动态堆叠既有 Imminent/Timing 行；MUST NOT 再画内容区「胖宝」或等价 App 名顶栏；MUST NOT 固定三行模板；Imminent 行 MUST NOT 恢复 nextAt 倒计时文案。

#### Scenario: No app brand row on lock screen

- **WHEN** 锁屏展示统一 Live Activity
- **THEN** 内容区 MUST NOT 出现居中或顶栏「胖宝」App 名文案

#### Scenario: Dynamic rows preserve kind styles

- **WHEN** `items` 含 imminent（有 duration expect）与 timing（有 expectEndAt）
- **THEN** imminent 行 MUST 仍为 logo+title+短版预计右槽；timing 行 MUST 仍为 logo+事件名+「预计 HH:mm 结束」副行+右侧已计时

#### Scenario: Empty expect on imminent row

- **WHEN** imminent 项无可用 expect 字段
- **THEN** 该行右槽 MUST 为空，MUST NOT 用 nextAt 填充倒计时

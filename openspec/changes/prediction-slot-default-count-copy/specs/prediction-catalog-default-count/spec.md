## ADDED Requirements

### Requirement: Feature catalog MUST expose defaultCount for prediction unlock
For `prediction_unlock` items in `GET /cash/app/api/feature/catalog`, the server MUST include a non-negative integer field `defaultCount` equal to the feature definition's default free slot count (`default_allowed_count` / `DefaultAllowedCount`). The server MUST NOT change how `allowedCount` is computed (`defaultCount + permanentDelta`, or existing full-access sentinel rules). Clients MUST treat missing `defaultCount` as unknown. 预测 catalog 项必须下发非负 `defaultCount`（定义表默认免费条数）；不得改动 allowedCount 合成；客户端缺字段视为未知。

#### Scenario: Catalog includes defaultCount for prediction
- **WHEN** a bound client fetches feature catalog and the list contains prediction_unlock
- **THEN** that item MUST include `defaultCount` as a non-negative integer matching the feature definition default free count

#### Scenario: allowedCount still includes purchases
- **WHEN** defaultCount is 2 and the device has permanentDelta 3
- **THEN** allowedCount MUST remain 5 (or the existing formula result) and defaultCount MUST remain 2

### Requirement: Full-slot dialog MUST use default copy only when enabledCount equals known defaultCount
When the prediction page shows the slot-full confirm dialog and `defaultCount` is present and greater than 0 and `enabledCount == defaultCount`, the message MUST state that those slots are default-enabled (「默认已开启」). When `defaultCount` is missing or null, the message MUST NOT contain the word「默认」. Slot gating MUST continue to use `allowedCount` only. 仅当 defaultCount 已知且 enabledCount 与其相等时满额文案可用「默认已开启」；缺 defaultCount 时文案不得出现「默认」；闸门仍只认 allowedCount。

#### Scenario: At default quota shows default-enabled copy
- **WHEN** defaultCount is 2, enabledCount is 2, allowedCount is 2, and the user tries to enable another forecast
- **THEN** the dialog message MUST indicate default-enabled slots (含「默认已开启」) and MUST still offer navigation to unlock hub on confirm

#### Scenario: Missing defaultCount never says 默认
- **WHEN** catalog omits defaultCount (legacy server) and the slot-full dialog is shown with allowedCount > 0
- **THEN** the message MUST NOT contain「默认」and MAY say already-enabled count only

#### Scenario: Purchased quota full without equaling default
- **WHEN** defaultCount is 2, allowedCount is 5, enabledCount is 5, and the slot-full dialog is shown
- **THEN** the message MUST NOT claim default-enabled solely because enabledCount equals allowedCount

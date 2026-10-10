## ADDED Requirements

### Requirement: Failed answer turn MUST restore prior ask question

When the client submits a growth-trajectory `answer` turn and the turn fails (SSE error event, business exception, transport failure, or the stream ends while still in streaming without a new question or result), the client MUST restore the previous in-memory question and return to the `asking` phase if a non-empty `sessionId` is still available. The client MUST NOT leave the UI permanently without that question solely because the answer attempt failed. Starting or restarting a predict turn MAY clear the question on failure as today. 提交追问失败时，在会话仍有效的前提下 **必须** 恢复原问题并回到 `asking`；**不得** 仅因提交失败就永久丢掉该追问。`start`/`restart` 失败时可清题。

#### Scenario: Answer SSE error restores question

- **WHEN** 用户处于 asking 并提交答案后 turn 下发 error（或等价失败）
- **THEN** 客户端 MUST 将 `phase` 恢复为 asking 且 MUST 再次展示提交前的同一 `question`
- **AND** MUST 保留可用于重试的 `sessionId`

#### Scenario: Leave and re-enter after failed answer

- **WHEN** 上述失败恢复后用户退出成长轨迹页再进入，且进程内 provider 未被 clear
- **THEN** 客户端 MUST 仍处于 asking 并展示该问题（`ensureLatest` MUST NOT 因 latestLoaded 误清掉该 asking 态）

#### Scenario: Start failure does not invent a question

- **WHEN** `start` 或 `restart` turn 失败且提交前无追问
- **THEN** 客户端 MUST NOT 伪造 question，phase MUST 为 idle 或 ready（有历史结果时）

### Requirement: ensureLatest MUST preserve in-memory ask across re-entry

When the growth-trajectory provider is already in `asking` (with a question) or `streaming`, `ensureLatest` (including `force: true` and re-entry from `GrowthTrajectoryScreen`) MUST return without clearing the question or changing phase to `idle`/`ready` solely due to unlock/catalog timing. The access gate for fetching latest MUST align with detail access (including trial), not only `isFeatureEffectivelyUnlocked`. 内存已处于 asking/streaming 时，`ensureLatest` **必须**保题且不得因开通/试用抖动把 phase 打成 idle；拉 latest 的门闸 **必须** 与可进详情（含试用）对齐。

#### Scenario: Leave asking and re-enter

- **WHEN** 用户在 asking 且有 question 时退出成长轨迹页再进入，且 provider 未被 `clear`
- **THEN** `ensureLatest` MUST NOT 清除该 question
- **AND** phase MUST 保持 asking，UI MUST 再次展示同一问题

#### Scenario: Trial user re-enter does not idle-wipe ask

- **WHEN** 用户仅试用可进详情（`canAccessFeatureDetail` 为真且未 effectively unlocked）并处于 asking
- **THEN** 再进页触发的 `ensureLatest` MUST NOT 因 `!isEffectivelyUnlocked` 将 phase 设为 idle

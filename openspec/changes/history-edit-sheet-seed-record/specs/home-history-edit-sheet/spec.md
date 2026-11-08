## ADDED Requirements

### Requirement: Edit sheet MUST accept seed record when absent from home list

When opening `showHomeHistoryEditSheet` with a `HistoryRecord`, the client MUST resolve the editable row as follows: if `homeHistoryProvider` contains that id, use the list row; otherwise, if the caller-supplied seed record’s id matches, use the seed to populate the sheet. The client MUST NOT toast「记录不存在」and dismiss solely because the id is missing from the near-window home list when a matching seed is provided. If the id is missing from home and no matching seed is available, the client MUST show an error affordance and MUST NOT leave an empty editable sheet open. 打开编辑 sheet 时：近窗有 id MUST 用列表行；无 id 但有匹配种子 MUST 用种子起表；不得仅因近窗缺失且已有种子而「记录不存在」并关闭；无列表且无种子 MUST 错误提示且不得空开可编辑 sheet。

#### Scenario: Seed opens outside home window

- **WHEN** 调用方传入 id=X 的种子 HistoryRecord，且 `homeHistoryProvider` 无 X
- **THEN** 编辑 Sheet MUST 以该种子字段展示并可编辑
- **AND** MUST NOT 仅因此弹出「记录不存在」并关闭

#### Scenario: Home list wins over seed

- **WHEN** `homeHistoryProvider` 含 id=X，且调用方同时传入种子 X
- **THEN** Sheet MUST 以列表中的记录为准起表

#### Scenario: No home and no seed still fails

- **WHEN** 打开编辑时 home 无该 id 且无匹配种子
- **THEN** 客户端 MUST 错误提示并 MUST NOT 保持空可编辑 Sheet

### Requirement: Seed-path save or delete MUST rely on API without forcing home insert

When the user saves or deletes a record that was opened via seed and is not present in `homeHistoryProvider`, the client MUST still call the existing update/delete APIs. On success the client MUST close the sheet. The client MUST NOT require inserting that record into the near-window home list for the operation to succeed; local replace/remove MAY be a no-op when the id is absent. 经种子打开且近窗无该 id 时，保存/删除 MUST 仍走既有 API；成功 MUST 关 sheet；MUST NOT 为成功而强制 insert 近窗；本地 replace/remove 在无 id 时 MAY noop。

#### Scenario: Save outside home succeeds via API

- **WHEN** 用户保存种子路径且近窗无该 id 的记录，且 update API 成功
- **THEN** 客户端 MUST 关闭 Sheet
- **AND** MUST NOT 因近窗无 id 而视为保存失败
- **AND** MUST NOT 仅为同步而强制将该条 insert 进 home 近窗

#### Scenario: Delete outside home succeeds via API

- **WHEN** 用户确认删除种子路径且近窗无该 id 的记录，且 delete API 成功
- **THEN** 客户端 MUST 关闭 Sheet
- **AND** MUST NOT 因近窗无 id 而视为删除失败

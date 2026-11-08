## ADDED Requirements

### Requirement: Appointment last-occurrence edit MUST work for records outside home window

After a successful unbounded filter fetch for appointment last-occurrence tap, the client MUST open the home history edit sheet such that a record absent from `homeHistoryProvider` still becomes editable via the seed-record path in `home-history-edit-sheet`. The client MUST NOT fail the flow with「记录不存在」solely because the record is outside the home near window. 预约上次点按 filter 成功后，近窗外记录 MUST 仍能经种子路径进入可编辑 sheet；MUST NOT 仅因不在 home 近窗而以「记录不存在」失败。

#### Scenario: Out-of-window appointment last opens edit

- **WHEN** 用户点按预约卡上次行，filter 返回 HistoryRecord X，且 home 近窗无 X
- **THEN** 客户端 MUST 打开可编辑的历史编辑 Sheet（以 X 为种子）
- **AND** MUST NOT 弹出「记录不存在」并立即关闭

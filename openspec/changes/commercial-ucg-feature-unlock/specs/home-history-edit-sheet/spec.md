## ADDED Requirements

### Requirement: History edit sheet SHALL restore square-sync toggle when sync gate is enabled

When `kHistorySquareSyncEnabled` is true, the home history edit sheet MUST follow `history-event-square-sync` visibility and save rules for「同步广场」(show toggle only with media; persist preference; allow UCG side effects when ON). When the gate was previously paused, the sheet MUST NOT keep forcing the pause-era hidden toggle / sync-OFF behavior.

当 `kHistorySquareSyncEnabled` 为 true 时，历史编辑 Sheet **必须** 恢复「同步广场」开关与同步开启时的 UCG 副作用，**不得** 继续沿用暂停期强制隐藏/强制关闭。

#### Scenario: 翻回后有媒体显示开关

- **WHEN** 同步闸门已翻回且编辑记录已选媒体
- **THEN** Sheet MUST 展示「同步广场」开关

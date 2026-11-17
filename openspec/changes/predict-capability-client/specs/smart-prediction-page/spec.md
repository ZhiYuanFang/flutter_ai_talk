## ADDED Requirements

### Requirement: Fixed-interval display rows SHALL offer an adjust-interval control beside predicted time

When a prediction row’s display-rail nextAt comes from a recall seed interval (including when predict display entitlement is inactive and seed forcing applies), the row MUST show a small control adjacent to the predicted time that opens the existing interval picker to update that root’s seed. Saving a new interval MUST refresh the display rail and MUST trigger the same local interval-mutation side effects as other seed upserts (including imminent pending sync request). Rows whose display nextAt comes from affinity while entitled MUST NOT be required to show this adjust control.

固定间隔展示的预测时刻旁 MUST 有调间隔小按钮；保存 MUST 刷新展示并触发间隔变更副作用。

#### Scenario: 未开通有种子可调间隔

- **WHEN** 用户未 entitle，根 A 展示种子 nextAt
- **THEN** A 行预测时刻旁 MUST 有可点的调间隔入口
- **AND** 用户选定新间隔后 MUST 更新种子且卡上 nextAt MUST 按新间隔重算

#### Scenario: 已开通亲和行不强制调间隔钮

- **WHEN** 用户已 entitle 且 A 行展示亲和 nextAt
- **THEN** 客户端 MUST NOT 要求仍展示「补充大概多久一次」大按钮作为唯一间隔入口

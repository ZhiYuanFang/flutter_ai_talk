## REMOVED Requirements

### Requirement: Prediction events locked by allowedCount
**Reason**: 产品删除预测槽位开通，预测事项不再按数量上锁。  
**Migration**: 智能预测页对真实事项不再叠加基于 `prediction_unlock.allowedCount` 的 `FeatureLockOverlay`；VIP/哨兵全开逻辑一并删除。

## ADDED Requirements

### Requirement: Smart prediction SHALL not apply commercial slot locks
The smart prediction page SHALL render real prediction events without commercial slot-count lock overlays driven by `prediction_unlock`. 智能预测页 **必须** 不再使用预测槽位商业锁。

#### Scenario: No slot overlay
- **WHEN** 用户打开智能预测页查看真实预测事项
- **THEN** MUST NOT 因槽位不足显示「点击开通」类槽位锁浮层

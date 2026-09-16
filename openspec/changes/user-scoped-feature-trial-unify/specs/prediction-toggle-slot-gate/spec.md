## REMOVED Requirements

### Requirement: Enabling forecast when slots full shows invite dialog
**Reason**: 预测槽位能力删除，不再存在满额开槽邀请闸。  
**Migration**: 预测开关 on 不再因 `allowedCount` 满额弹出「预测槽位已满」邀请框；删除对 `featureId=prediction_unlock` 的兑码开槽路径。

## ADDED Requirements

### Requirement: Forecast toggle SHALL not be gated by prediction slot cap
Turning forecast on for an event SHALL NOT be blocked by a commercial prediction slot cap or slot-full invite redemption flow. 开启预测 **不得** 再受槽位上限或满额邀码闸限制。

#### Scenario: Toggle on without slot dialog
- **WHEN** 非 VIP 用户在曾受槽位限制的场景下打开某事项预测开关
- **THEN** MUST NOT 弹出「预测槽位已满」邀请对话框；开关 MUST 按非槽位业务规则处理（若另有非商业规则则仍可适用）

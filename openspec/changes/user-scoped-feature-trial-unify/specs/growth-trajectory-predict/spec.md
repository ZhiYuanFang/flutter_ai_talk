## ADDED Requirements

### Requirement: Growth latest result SHALL be user-isolated
Growth trajectory latest results SHALL be stored and returned per `(wx_id, device_no)`. Entering the growth detail page SHALL auto-load that user's latest cache for the current baby without consuming the daily quota. 成长轨迹最新结果 **必须** 用户隔离；进详情自动加载缓存且不扣次。

#### Scenario: Load cache on enter
- **WHEN** 用户进入成长轨迹详情且该用户该宝宝已有 latest
- **THEN** 界面 MUST 展示该缓存结果且 MUST NOT 因此增加 usedToday

#### Scenario: Other user cannot see
- **WHEN** 另一账号绑定同一宝宝进入成长详情
- **THEN** MUST NOT 自动展示前一账号的结果

### Requirement: Growth generation SHALL support trial soft access and claim
Growth prediction generation SHALL authorize soft access when `trialAvailable` and SHALL claim 24h user entitlement on first successful persistence per `feature-free-trial`. 成长轨迹生成 **必须** 支持试用 soft access 与首次成功 claim。

#### Scenario: Trial first success
- **WHEN** `trialAvailable` 用户完成一次成功的轨迹预测落库
- **THEN** MUST claim 24h 用户权益并消耗试用资格

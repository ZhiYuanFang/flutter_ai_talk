## ADDED Requirements

### Requirement: Unlock hub care unqualified hint MAY reuse progress fields
When the feature unlock hub shows the care-alert card in a feeding-unqualified state and eligibility data is available, the bottom hint SHOULD prefer client-composed progress from `effectiveDays`, `requiredDays`, and `remainingDays` consistent with other care-alert unqualified surfaces. The client MUST NOT treat server `message` as the authoritative source for those numbers. When eligibility data is missing (loading/failed), the hub MAY show a short fixed unmet-threshold or loading/retry copy instead. 开通中心 care 未达标底部提示在有数据时 **宜** 复用 X/N 进度字段；**不得** 以 `message` 为数字权威；无数据时可用短文案。

#### Scenario: Progress hint when data present
- **WHEN** 开通中心 care 卡未达标且 eligibility 返回 `effectiveDays`/`requiredDays`/`remainingDays`
- **THEN** 底部提示 MUST 能体现已累计与要求天数（或等价进度语义）
- **AND** MUST NOT 仅依赖 `message` 拼出这些数字

#### Scenario: Short copy when data absent
- **WHEN** 开通中心 care 卡未达标且尚无 eligibility data
- **THEN** 底部 MAY 展示简短未达标或校验中文案

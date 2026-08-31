## ADDED Requirements

### Requirement: Unqualified eligibility progress MUST show completed and remaining days
When rendering feeding-eligibility progress for UCG entry lock or care-alert（值得留意）unqualified state, the client MUST compose copy from `effectiveDays`, `requiredDays`, and `remainingDays` (client-side). The progress UI MUST show a first line that communicates completed effective days versus required days (e.g.「已累计 X / N 天有效喂养」), and a second line that communicates remaining days toward the feature goal. The client MUST emphasize the numeric fields visually. The client MUST NOT use server `message` as the authoritative source for those numbers, and MUST NOT be required to tell the user that「今日不计入」. 未合格进度 MUST 两行展示已累计 X/N 与还需 Y 天；数字强调；不以 message 为权威。

#### Scenario: Care-alert shows completed over required
- **WHEN** care-alert eligibility returns `qualified=false`、`effectiveDays=1`、`requiredDays=2`、`remainingDays=1`
- **THEN** the care-alert progress UI MUST show completed effective days as 1 against required 2, and remaining 1 day toward activating care-alert

#### Scenario: UCG lock shows completed over required
- **WHEN** UCG eligibility returns `qualified=false`、`effectiveDays=3`、`requiredDays=7`、`remainingDays=4`
- **THEN** the UCG lock progress UI MUST show completed effective days as 3 against required 7, and remaining days toward unlocking the square

#### Scenario: No today-exclusion copy required
- **WHEN** unqualified progress copy is shown
- **THEN** the copy MUST NOT be required to include「今日不计入」or equivalent rule-book wording

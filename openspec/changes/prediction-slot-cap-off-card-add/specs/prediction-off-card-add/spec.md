## ADDED Requirements

### Requirement: Forecast-off card tap MUST add event without supplement
On hot-state prediction event cards (logged-in, baby bound, not demo skeleton), when `forecastEnabled` is false and the card is not in active timing, a tap on the card body MUST open the feeding add flow with `EventRecordIntent.add`, including when `lastAt` is null. The client MUST NOT use `EventRecordIntent.supplement` for that tap. Forecast-off cards MUST still omit the「补充上一次」and interval-recall CTAs. The「上一次」label edit path MUST remain available independently of forecastEnabled. 热态关推演且非计时中时，点卡必须走 add（含无 lastAt），不得走 supplement；关推演仍不展示补齐/间隔 CTA；「上一次」编辑不受推演开关影响。

#### Scenario: Forecast off with lastAt taps card to add
- **WHEN** a hot card has forecastEnabled false, lastAt non-null, and is not active timing, and the user taps the card body
- **THEN** the client MUST start EventRecordIntent.add (not supplement, not no-op)

#### Scenario: Forecast off without lastAt taps card to add
- **WHEN** a hot card has forecastEnabled false, lastAt null, and is not active timing, and the user taps the card body
- **THEN** the client MUST start EventRecordIntent.add and MUST NOT start supplement onboarding

#### Scenario: Forecast on without lastAt still supplements
- **WHEN** a hot card has forecastEnabled true, lastAt null, and the user taps the card body (or「补充上一次」CTA)
- **THEN** the client MUST keep using EventRecordIntent.supplement as today

#### Scenario: Forecast off hides supplement CTAs
- **WHEN** a hot card has forecastEnabled false
- **THEN** the client MUST NOT show「补充上一次」or interval-recall CTAs on that card

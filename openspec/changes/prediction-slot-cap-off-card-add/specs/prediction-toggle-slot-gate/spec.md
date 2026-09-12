## ADDED Requirements

### Requirement: Excess enabled forecasts MUST be aligned by slot cap
The forecast toggle slot gate (enable blocked when full, VIP bypass, disable always allowed, no FeatureLockOverlay) MUST remain in effect. In addition, for non-VIP hot state after VIP settlement, when `enabledCount` already exceeds permanent `allowedCount`, the client MUST NOT leave the excess enabled indefinitely; it MUST align by disabling surplus enables per `prediction-slot-enabled-cap`. This supersedes the prior non-goal of never auto-closing already-enabled excess items for non-VIP users. 满额再开闸与 VIP 放行、关开关、无锁浮层保持；非 VIP 热态超额已开不得长期保留，必须按 prediction-slot-enabled-cap 关闭多余项（废止「不自动关超额存量」）。

#### Scenario: Over-quota stock is closed not only blocked on next enable
- **WHEN** isVip is false, allowedCount is 2, and 5 events already have forecast enabled on hot load
- **THEN** the client MUST reduce enabled forecasts to 2 even if the user does not attempt to enable another event

#### Scenario: Enable-when-full dialog still applies
- **WHEN** isVip is false, allowedCount is 2, enabledCount is 2 after alignment, and the user turns on forecast for another event
- **THEN** that event remains disabled and the existing slot confirm dialog / unlock navigation behavior MUST still apply

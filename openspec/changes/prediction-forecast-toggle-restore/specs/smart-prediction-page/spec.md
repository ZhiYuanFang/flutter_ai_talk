## REMOVED Requirements

### Requirement: All listed events SHALL participate in forecast without a per-event toggle

**Reason**: 产品恢复每事件推演开关。  
**Migration**: 使用本 change「紧凑推演开关」Requirement。

## ADDED Requirements

### Requirement: Per-event compact forecast toggle SHALL appear in list and grid layouts

Each prediction event card in both vertical list and two-column grid layouts SHALL expose a compact forecast（推演）toggle defaulting to ON. Toggle state MUST persist locally across app restarts. When OFF, the client MUST gray out the card, MUST NOT show relative-time copy for that event, and MUST NOT render that event’s chart. The home prediction tip MUST NOT select an event while its forecast is OFF.

纵向与网格卡片 **必须** 提供紧凑推演开关（默认开、本地持久化）；关闭后 **必须** 置灰、无相对时间、无折线；首页 tip **不得** 选用关闭推演的事件。

#### Scenario: 网格关闭推演

- **WHEN** 用户在网格布局关闭事件 A 的推演
- **THEN** A 卡 MUST 置灰
- **AND** MUST NOT 展示 A 的相对时间与折线

#### Scenario: 重启保持关闭

- **WHEN** 用户关闭事件 A 推演后杀死并重启 App
- **THEN** A 的推演开关 MUST 仍为关闭

# Specification - Home WS Status Display

## ADDED Requirements

### Requirement: Conditional WS Status Banner Visibility

The system SHALL hide the WebSocket disconnect banner on the Home screen when the user has not yet bound a baby to their account.
当用户尚未将其账户与宝宝信息绑定时，系统必须隐藏主页上的 WebSocket 断开连接提示 Banner。

#### Scenario: Suppress banner when baby is unbound

- **WHEN** the user is on the Home screen
- **WHEN** `needsDeviceBind` is true (indicating no baby is bound)
- **WHEN** the WebSocket connection is disconnected
- **THEN** the `HomeHistoryWsStatusBanner` SHALL NOT be visible

#### Scenario: Show banner when baby is bound

- **WHEN** the user is on the Home screen
- **WHEN** `needsDeviceBind` is false (indicating a baby is bound)
- **WHEN** the WebSocket connection is disconnected
- **THEN** the `HomeHistoryWsStatusBanner` SHALL be visible

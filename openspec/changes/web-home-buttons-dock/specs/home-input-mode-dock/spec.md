## MODIFIED Requirements

### Requirement: Collapsed dock shows current mode as edge-flush semicircle

The home input mode dock SHALL display only the **current** input mode icon in a **semicircle** flush to a screen edge when idle, with approximately half of the control visible inside the viewport. 静止态下，dock MUST 以贴边**半圆**展示**当前**模式图标；按下/轮转动画期间允许临时变为全圆（见 ADDED 需求）。

#### Scenario: Voice mode collapsed on right edge

- **WHEN** the user is on the home screen with input mode `voice` on Android/iOS and the dock is idle on the right edge
- **THEN** a semicircular control flush to the right edge shows the voice (microphone) icon with roughly half the circle visible on screen

#### Scenario: Mode icon updates after switch

- **WHEN** the user cycles to a different input mode via the dock
- **THEN** the dock icon MUST update to the new mode (grid for buttons, microphone for voice on mobile, keyboard for text on Web) without requiring an app restart

### Requirement: Dock integrates with existing input mode rules

The dock SHALL reuse existing input channel selection, persistence (`HomeInputChannelStore`), and availability rules, with platform-specific cycle sets: Android/iOS MUST cycle **voice** and **buttons** only; Web MUST cycle **buttons** and **text** only. dock MUST 复用既有 channel 选择与持久化；Android/iOS 轮转集合 MUST 仅为 **voice** 与 **buttons**；Web 轮转集合 MUST 仅为 **buttons** 与 **text**。

#### Scenario: Web dock 显示且 buttons 与 text 轮转

- **WHEN** 用户在 Web 上已登录且已绑宝宝，主页未处于 `blockHomeInputChrome`
- **THEN** dock MUST 显示，且每次有效点击松开 MUST 在 buttons 与 text 模式间交替切换

#### Scenario: Web 游客或未绑宝宝不显示 dock

- **WHEN** 用户在 Web 上处于游客态或未绑宝宝（`blockHomeInputChrome` 为真）
- **THEN** dock MUST NOT 显示

#### Scenario: Mobile cycle includes buttons and voice

- **WHEN** the home screen runs on Android or iOS with buttons input supported
- **THEN** each tap-release cycle MUST alternate between buttons and voice modes

#### Scenario: Ignored persisted text on mobile

- **WHEN** persisted channel is `text` on Android/iOS
- **THEN** restore MUST treat it as invalid and keep default `buttons`（方案 A）

#### Scenario: Ignored persisted voice on Web

- **WHEN** persisted channel is `voice` on Web
- **THEN** restore MUST treat it as invalid and keep default `buttons`

### Requirement: 松开时轮转下一输入模式

The dock SHALL cycle to the next available input mode on a tap release (not on pointer down), without an expanded mode picker menu. 贴边 dock MUST 在用户**松开**且判定为点击（非拖动）时，立即切换到**下一个**可用输入模式；**不得**再展示展开式多选菜单。

#### Scenario: 移动端 buttons 与 voice 轮转

- **WHEN** 用户在 Android/iOS 上松开 dock 且当前为按钮模式
- **THEN** 系统 MUST 切换到语音模式，并通过既有 `onChannelSelected` / `_selectInputChannel` 逻辑更新 UI 与持久化

#### Scenario: 再次松开轮转回按钮

- **WHEN** 用户在 Android/iOS 上当前为语音模式且用户再次点击松开 dock
- **THEN** 系统 MUST 切换回按钮模式

#### Scenario: Web buttons 与 text 轮转

- **WHEN** 用户在 Web 上松开 dock 且当前为按钮模式
- **THEN** 系统 MUST 切换到文字模式，并通过既有 `onChannelSelected` / `_selectInputChannel` 逻辑更新 UI 与持久化

#### Scenario: Web 再次松开轮转回按钮

- **WHEN** 用户在 Web 上当前为文字模式且用户再次点击松开 dock
- **THEN** 系统 MUST 切换回按钮模式

#### Scenario: 拖动不触发轮转

- **WHEN** 用户拖动 dock 超过 tap 位移阈值后松开
- **THEN** 系统 MUST 仅执行贴边吸附，MUST NOT 变更输入模式

## REMOVED Requirements

### Requirement: Dock integrates with existing input mode rules（Web text-only 不显示 dock 场景）

**Reason**: 原 Scenario「Web text-only 不显示 dock」与「Web 规则不变」条款已被 MODIFIED 块替代；Web 现在在非 block 状态下默认显示 dock 并在 buttons↔text 间轮转。

**Migration**: 删除对 `WEB_HOME_INPUT` 与 `_canSwitchInputMode` 的 Web text-only 分支；Web dock 显示条件与移动端对齐（仅 `blockHomeInputChrome` 隐藏）。

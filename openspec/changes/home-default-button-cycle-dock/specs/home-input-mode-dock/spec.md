## ADDED Requirements

### Requirement: 松开时轮转下一输入模式

The dock SHALL cycle to the next available input mode on a tap release (not on pointer down), without an expanded mode picker menu. 贴边 dock MUST 在用户**松开**且判定为点击（非拖动）时，立即切换到**下一个**可用输入模式；**不得**再展示展开式多选菜单。

#### Scenario: 移动端 buttons 与 voice 轮转

- **WHEN** 用户在 Android/iOS 上松开 dock 且当前为按钮模式
- **THEN** 系统 MUST 切换到语音模式，并通过既有 `onChannelSelected` / `_selectInputChannel` 逻辑更新 UI 与持久化

#### Scenario: 再次松开轮转回按钮

- **WHEN** 当前为语音模式且用户再次点击松开 dock
- **THEN** 系统 MUST 切换回按钮模式

#### Scenario: 拖动不触发轮转

- **WHEN** 用户拖动 dock 超过 tap 位移阈值后松开
- **THEN** 系统 MUST 仅执行贴边吸附，MUST NOT 变更输入模式

### Requirement: 按下全圆与 pop 轮转动画

The dock SHALL reveal a **full circle** when engaged and SHALL play a pop scale animation on the new mode icon while staying full circle until the animation completes, then return to edge-flush semicircle. 用户**按下** dock 时 MUST 将控件内移展示**完整圆形**；**松开轮转**时 MUST 对新模式图标播放 pop 缩放动画（略放大再缩回，曲线参考 `HomeEventRecordFlyOverlay` pop 段）；动画期间 MUST 保持全圆位置；动画结束后 MUST 回到贴边半圆静止态。

#### Scenario: 按下展示全圆

- **WHEN** 用户按下贴边半圆 dock 且未进入拖动
- **THEN** dock MUST 动画内移至全圆可见位置（圆心沿屏内法向内移一个半径）

#### Scenario: pop 动画期间保持全圆

- **WHEN** 用户松开触发模式轮转
- **THEN** 图标 MUST 立即更新为新模式，并播放 pop 缩放；在整个 pop 动画完成前 MUST 保持全圆位置

#### Scenario: 动画结束回半圆

- **WHEN** pop 动画完成
- **THEN** dock MUST 动画回到贴边半圆静止位置，图标为当前模式

## MODIFIED Requirements

### Requirement: Collapsed dock shows current mode as edge-flush semicircle

The home input mode dock SHALL display only the **current** input mode icon in a **semicircle** flush to a screen edge when idle, with approximately half of the control visible inside the viewport. 静止态下，dock MUST 以贴边**半圆**展示**当前**模式图标；按下/轮转动画期间允许临时变为全圆（见 ADDED 需求）。

#### Scenario: Voice mode collapsed on right edge

- **WHEN** the user is on the home screen with input mode `voice` and the dock is idle on the right edge
- **THEN** a semicircular control flush to the right edge shows the voice (microphone) icon with roughly half the circle visible on screen

#### Scenario: Mode icon updates after switch

- **WHEN** the user cycles to a different input mode via the dock
- **THEN** the dock icon MUST update to the new mode (grid for buttons, microphone for voice) without requiring an app restart

### Requirement: Dock integrates with existing input mode rules

The dock SHALL reuse existing input channel selection, persistence (`HomeInputChannelStore`), and availability rules (`_showButtonsInputMode`, Web `WEB_HOME_INPUT` / `_canSwitchInputMode`), with mobile cycling only **voice** and **buttons**. dock MUST 复用既有 channel 选择与持久化；Android/iOS 轮转集合 MUST 仅为 **voice** 与 **buttons**；Web 规则不变。

#### Scenario: Buttons hidden on Web text-only

- **WHEN** the home screen runs on Web with text-only input policy
- **THEN** the dock is not shown

#### Scenario: Mobile cycle includes buttons and voice

- **WHEN** the home screen runs on Android or iOS with buttons input supported
- **THEN** each tap-release cycle MUST alternate between buttons and voice modes

#### Scenario: Ignored persisted text on mobile

- **WHEN** persisted channel is `text` on Android/iOS
- **THEN** restore MUST treat it as invalid and keep default `buttons` (方案 A)

## REMOVED Requirements

### Requirement: Tap collapsed expands; select mode or outside tap collapses

**Reason**: 模式切换改为一键轮转，不再需要展开式多选菜单与外部 dismiss。

**Migration**: 用户通过贴边 dock 松开即可在 voice 与 buttons 间切换；无需二次点选。

### Requirement: Expand layout follows docked edge orientation

**Reason**: 展开菜单 UI 已移除。

**Migration**: 无；轮转不依赖菜单布局。

### Requirement: Expanded dock must not block core input gestures in the bottom panel

**Reason**: 不再有 expanded 状态与历史区 dismiss 遮罩。

**Migration**: 半圆/全圆 dock 不得遮挡底部主输入区核心手势；拖动与 tap 仍须与语音球、事件网格手势区分。

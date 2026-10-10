## ADDED Requirements

### Requirement: Portrait voice dock host MUST be home shell

In portrait orientation, when `kPredictionPortraitVoiceEnabled` is true, the client MUST mount the EdgeDock portrait voice ball (and independent subtitle toast) on the home shell (`UcgHomeShell` or equivalent) above the home PageView, so the ball remains available on feeding, prediction, and UCG pages while the shell route is current. The smart prediction screen MUST NOT mount a second portrait EdgeDock instance. 竖屏 flag 开启时，贴边球与字幕 toast **必须** 挂在主壳 PageView 之上，喂养/预测/UCG 竖屏可见；预测页 **不得** 再挂第二颗竖屏球。

#### Scenario: 喂养页可见竖屏球

- **WHEN** `kPredictionPortraitVoiceEnabled` 为 true 且用户在主壳喂养页竖屏且主壳为当前路由
- **THEN** UI MUST 展示 EdgeDockShell 竖屏语音球

#### Scenario: 预测页无双球

- **WHEN** 用户在主壳预测页竖屏
- **THEN** 客户端 MUST 仅渲染一颗竖屏语音球（壳层宿主）
- **AND** MUST NOT 在 `SmartPredictionScreen` 内再挂一套竖屏 EdgeDock

### Requirement: Portrait voice activate MUST follow shell route currency

For portrait prediction voice, the client MUST treat session `want` as true only when the home shell route is the current route (`ModalRoute.isCurrent` or equivalent), portrait orientation applies, `kPredictionPortraitVoiceEnabled` is true, and the platform is non-web Android/iOS. The client MUST NOT require the prediction PageView page to be visible for portrait activate. When the user pushes a covering route over the home shell, the client MUST deactivate portrait voice. 竖屏会话 activate **必须** 以主壳为当前路由为准，**不得** 再要求预测页可见；推入覆盖路由时 MUST deactivate。

#### Scenario: 切到喂养仍保持会话资格

- **WHEN** 竖屏 flag 开启且用户从预测滑到喂养（主壳仍为当前路由）
- **THEN** 客户端 MUST 保持或重新满足竖屏 `activate` 条件（不得因离开预测页而强制长期 deactivate）

#### Scenario: 推入设置后 deactivate

- **WHEN** 用户从主壳推入设置（或其它覆盖主壳的路由）
- **THEN** 客户端 MUST deactivate 竖屏预测语音会话

### Requirement: Portrait voice MUST hide on unqualified UCG page

When the home PageView current page is UCG and UCG eligibility is not qualified, the client MUST NOT show the portrait voice EdgeDock (or portrait voice subtitle toast) above the UCG feature lock, and MUST NOT keep portrait voice activated solely for that locked page. 当前页为 UCG 且未合格时 **必须** 藏竖屏球与字幕，且 **不得** 仅因锁页而保持 activate。

#### Scenario: 未合格 UCG 无球

- **WHEN** 用户滑到 UCG 页且资格未合格
- **THEN** UI MUST NOT 展示竖屏语音球叠在 FeatureLockOverlay 上
- **AND** 客户端 MUST deactivate 或等效停止竖屏预测语音会话

## MODIFIED Requirements

### Requirement: Portrait prediction voice entry MUST use EdgeDockShell

On the **home shell** in **portrait** orientation, when portrait prediction-voice UI is shown, the client MUST present the listen affordance inside the shared `EdgeDockShell` (or equivalent wrapper that uses that shell), supporting edge peek (semicircle), edge engaged (full circle), and floating placements with drag-to-snap. The client MUST NOT keep a permanently fixed non-dockable chip as the only portrait listen control. **Landscape** prediction MUST keep a fixed listen chip on the smart prediction page and MUST NOT wrap that chip in `EdgeDockShell` in this change.

主壳**竖屏**展示预测语音入口时，客户端 **必须** 用共享 `EdgeDockShell`（或等价包装）呈现监听入口，支持贴边半圆 peek、贴边全圆 engaged、浮空 floating 及拖动吸附。**不得** 仅保留不可贴边收起的固定 chip 作为竖屏唯一入口。**横屏** **必须** 继续在智能预测页使用固定监听 chip，本变更 **不得** 为其包 `EdgeDockShell`。

#### Scenario: 竖屏为贴边球

- **WHEN** 用户在主壳竖屏且语音入口可见
- **THEN** UI MUST 展示可拖动的 EdgeDockShell 语音球（非仅固定 Positioned 胶囊）

#### Scenario: 横屏仍固定 chip

- **WHEN** 用户在智能预测页横屏且语音入口可见
- **THEN** UI MUST 展示固定位置的监听 chip
- **AND** MUST NOT 使用 EdgeDockShell 包裹该横屏 chip

### Requirement: Portrait prediction voice MAY be gated off without landscape impact

When `kPredictionPortraitVoiceEnabled` (or equivalent compile-time flag) is `false`, the home shell in **portrait** MUST NOT show any prediction-voice entry (EdgeDock ball, listen chip, subtitle toast, or placeholder), and MUST NOT activate the prediction voice session / request microphone solely because the home shell is visible in portrait. When the flag is `true`, portrait voice MUST follow the EdgeDockShell portrait voice dock requirements on the home shell, and the client MUST call `LandscapeVoiceController.activate` (including via `syncLandscapeVoiceLifecycle` or equivalent) when portrait shell-voice surface want is true on non-web Android/iOS. **Landscape** prediction voice (fixed listen chip and session lifecycle gated by prediction page visibility) MUST remain available regardless of this portrait flag. The product shipping default for `kPredictionPortraitVoiceEnabled` MUST be `true` (flip to `false` only for emergency disable).

当竖屏语音开关为 `false` 时，主壳**竖屏** MUST NOT 展示任何预测语音入口，且 MUST NOT 仅因主壳竖屏可见而 activate 会话或请求麦克风。开关为 `true` 时竖屏 MUST 在主壳遵循贴边球契约，且在非 Web 的 Android/iOS 竖屏壳层 surface want 为真时 MUST 经 `syncLandscapeVoiceLifecycle`（或等价）调用 `activate`。**横屏** 预测语音 MUST 不受该竖屏开关关闭（仍按预测页可见门禁）。产品发版默认 `kPredictionPortraitVoiceEnabled` MUST 为 `true`（仅紧急关闭时翻 `false`）。

#### Scenario: 竖屏暂停无入口

- **WHEN** `kPredictionPortraitVoiceEnabled` 为 false 且用户在主壳竖屏
- **THEN** UI MUST NOT 展示语音贴边球、监听 chip、语音字幕 toast 或「暂未开放」类占位入口
- **AND** 客户端 MUST NOT 因主壳竖屏可见而 activate 预测语音会话或弹出麦克风权限

#### Scenario: 横屏仍开放

- **WHEN** `kPredictionPortraitVoiceEnabled` 为 false 且用户在智能预测页横屏
- **THEN** UI MUST 仍展示横屏固定监听 chip（语音可用时）
- **AND** 预测语音生命周期 MUST 仍可按横屏∩预测可见规则 activate

#### Scenario: 开关翻回恢复竖屏球

- **WHEN** `kPredictionPortraitVoiceEnabled` 为 true 且用户在主壳竖屏、主壳为当前路由、非 UCG 未合格锁态，且语音可用
- **THEN** UI MUST 恢复 EdgeDockShell 竖屏语音球（及既有 peek/engaged/字幕契约）

#### Scenario: 竖屏 flag 开启时会话 MUST activate

- **WHEN** `kPredictionPortraitVoiceEnabled == true` 且非 Web 的 Android/iOS、主壳为当前路由、竖屏、且非 UCG 未合格锁态
- **THEN** 客户端 MUST 调用 `LandscapeVoiceController.activate`（含经 `syncLandscapeVoiceLifecycle`）
- **AND** MUST NOT 仅渲染贴边球而不激活会话

#### Scenario: 产品默认开启竖屏语音

- **WHEN** 使用发版默认编译配置（未人为将竖屏 flag 翻为 false）
- **THEN** `kPredictionPortraitVoiceEnabled` MUST 为 `true`

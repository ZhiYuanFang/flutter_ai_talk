## ADDED Requirements

### Requirement: Prediction voice MUST re-activate when deviceNo arrives while surface wants session

While the prediction voice surface want is true (landscape prediction visible or portrait shell-voice surface, per existing lifecycle gates) and the shared voice session is not yet active because `deviceNo` was missing or empty at the first activate attempt, the client MUST attempt `LandscapeVoiceController.activate` again when `deviceNo` becomes a non-empty value (e.g. after local cache refresh or bind). The re-activate path MUST use the same microphone soft-check rules as surface-visible activate (MUST NOT prompt for microphone solely because `deviceNo` arrived). The client MUST NOT leave the listen affordance permanently showing the bind-baby caption after a non-empty `deviceNo` is available and surface want remains true. 当预测语音 surface want 为真，且因首次 activate 时 `deviceNo` 缺失/为空而未能激活会话时，客户端 MUST 在 `deviceNo` 变为非空后再次尝试 `activate`。补激活 MUST 遵循表面可见 soft-check 麦权规则（MUST NOT 仅因 dn 到达而弹用途框/系统申请）。在 dn 已非空且 surface want 仍为真时，MUST NOT 让监听入口永久停留在「绑定宝宝」类文案。

#### Scenario: 冷启 dn 晚到后补激活

- **WHEN** 用户进入预测语音表面时 `deviceNo` 尚为空，监听入口曾提示需绑定宝宝
- **AND** 随后本地 `deviceNo` 变为非空，且 surface want 仍为真
- **THEN** 客户端 MUST 再次调用 `activate`（或等价补激活）
- **AND** MUST NOT 在仅因 dn 到达时弹出麦克风用途框或系统权限申请

#### Scenario: 已授权则进入可唤醒

- **WHEN** 上述补激活发生且麦克风权限已授予
- **THEN** 客户端 MUST 进入可本地监听「胖宝」的状态（或等价 listening 就绪）
- **AND** 监听入口 MUST NOT 继续展示「绑定宝宝后可语音…」

#### Scenario: 未授权则 micDenied 点按路径

- **WHEN** 上述补激活发生且麦克风尚未授权
- **THEN** 客户端 MUST 进入未授权可读状态（可点按申请）
- **AND** MUST NOT 自动弹出用途框（遵循 soft-check）

#### Scenario: 离表面后 dn 到达不误开

- **WHEN** 预测语音 surface want 已为 false（已 deactivate）
- **AND** 随后 `deviceNo` 才变为非空
- **THEN** 客户端 MUST NOT 仅因此启动预测语音会话或开麦

### Requirement: Listen affordance tap MAY retry activate when session inactive with deviceNo

When the user taps the landscape listen chip or portrait voice ball while the prediction voice session is not active and a non-empty `deviceNo` is already available, the client MUST attempt to activate (or complete mic grant + arm wake per existing mic rules) rather than no-op. If `deviceNo` is still empty, the client MAY keep the bind-baby caption. 当用户点按监听入口且会话未激活、但 `deviceNo` 已非空时，客户端 MUST 尝试激活（或按既有麦权规则完成申请并武装唤醒），MUST NOT 无操作吞掉点按。若 dn 仍空，MAY 保持绑定提示。

#### Scenario: 未激活但已绑定点球补激活

- **WHEN** 预测语音会话未激活，`deviceNo` 已非空，用户点按监听 chip 或竖屏语音球
- **THEN** 客户端 MUST 尝试 activate 或等价补会话/麦权路径

## ADDED Requirements

### Requirement: 横屏语音字幕弹幕 MUST 经主题语义原子取色

The landscape voice subtitle toast MUST obtain its background, foreground text, and optional border colors only via `AppColor` semantic atoms (panelGlass family and/or paired on-panel text) or documented `AppVisualTokens` fields. It MUST NOT use hardcoded black/gray fills such as `Colors.black` with ad-hoc alpha for the toast chrome. 横屏语音字幕弹幕的底色、前景字色与可选描边 MUST 仅经 `AppColor` 语义原子（panelGlass 族及配对 on-panel 字色）或已文档化的 `AppVisualTokens` 字段取得；MUST NOT 使用 `Colors.black` 等硬编码底作为弹幕 chrome。

#### Scenario: 切换主题后弹幕跟色

- **WHEN** 用户切换应用主题/调色板且字幕非空
- **THEN** 弹幕底与字色 MUST 随当前 panelGlass / onPanelGlass（或等价原子）更新
- **AND** MUST NOT 保持固定黑底

#### Scenario: 禁止黑底硬编码

- **WHEN** 审查 `_LandscapeVoiceSubtitleToast` 实现
- **THEN** 弹幕容器填充 MUST NOT 为 `Colors.black`（及等价硬编码近黑）拼 alpha

### Requirement: 监听 chip MUST 与弹幕同属 panelGlass 浮层语言

The landscape voice listen chip chrome MUST use the same panelGlass semantic family for surface and on-panel text as the subtitle toast, and connection indicator colors MUST come from Theme `ColorScheme` semantic colors (e.g. error for disconnected, primary or tertiary for connected) rather than business-inline pastel hex literals. 横屏语音监听 chip 的表面与压在其上的文案 MUST 与字幕弹幕同属 panelGlass 语义族；连接指示点色 MUST 取自 Theme `ColorScheme` 语义色（如未连用 error、已连用 primary 或 tertiary），MUST NOT 使用业务内联马卡龙 hex。

#### Scenario: chip 与弹幕配对

- **WHEN** 横屏同时展示监听 chip 与字幕弹幕
- **THEN** 二者表面 MUST 均可追溯到 panelGlass 原子
- **AND** chip 主文案 MUST 使用 onPanelGlass（或文档化等价）而非随意 `Colors.white`

#### Scenario: 连接点无马卡龙 hex

- **WHEN** 渲染已连/未连指示点
- **THEN** 颜色 MUST 来自 `ColorScheme`（或后续正式 `AppColor` 状态原子）
- **AND** MUST NOT 保留无注释例外的 `Color(0xFF2EAD4B)` / `Color(0xFFE04545)` 业务硬编码

### Requirement: 弹幕 MUST 提供短出现过渡且圆角与 chip 族接近

When the subtitle toast becomes visible, the UI MUST apply a short fade-in (on the order of ~150–250ms) without blocking pointer events (toast remains non-interactive). Toast corner radius MUST be visually aligned with the listen chip family (chip ~20; toast MUST NOT remain a clearly mismatched sharp 12-only look without rationale). 字幕弹幕变为可见时，UI MUST 施加短淡入（约 150–250ms），且 MUST NOT 拦截点击（保持 IgnorePointer）。弹幕圆角 MUST 与监听 chip 族视觉接近（chip 约 20；弹幕 MUST NOT 无理由维持明显违和的过尖小圆角）。

#### Scenario: 字幕出现淡入

- **WHEN** 字幕由空变为非空并插入 toast
- **THEN** MUST 可见短淡入过渡
- **AND** toast MUST 仍为 IgnorePointer（不抢占横屏手势）

#### Scenario: 圆角对齐

- **WHEN** 并排观察 chip 与弹幕
- **THEN** 弹幕圆角 MUST 与 chip 同族（建议 ≥16，贴近 20）

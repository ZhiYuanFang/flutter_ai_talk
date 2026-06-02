## MODIFIED Requirements

### Requirement: 缺省 logo 与色调

The UI SHALL show a bundled placeholder image when an event has no usable local logo file; on non-Web platforms it MUST NOT use `Image.network` while a logo URL exists but the local file is not yet ready. 当事件无可用本地 logo 文件时，界面必须使用应用内**占位图**资源；当事件无有效 `color` 时，界面必须使用当前上下文的**主色调**（`Theme.colorScheme.primary`）；**非 Web** 平台在 `logoUrl` 非空但 `localLogoPath` 缺失或文件不存在时 **MUST** 显示占位图，**不得**使用网络 URL 作为过渡展示。

#### Scenario: 无 logo

- **WHEN** 某事件无 `localLogoPath` 且 `logo` URL 为空或不可用
- **THEN** 所有展示位必须显示同一占位图，且尺寸符合各场景约束

#### Scenario: 有 URL 但本地未就绪

- **WHEN** 非 Web 平台某事件 `logoUrl` 非空但本地文件尚未下载完成或 `localLogoPath` 不可用
- **THEN** 所有 `EventLogo` 展示位 MUST 显示占位图，且 MUST NOT 发起 `Image.network` 加载；当后台下载完成且 state 更新后 MUST 自动切换为本地文件图

#### Scenario: 无色调

- **WHEN** 某事件的 `color` 缺失或解析失败
- **THEN** 该事件相关强调色（圆点、文字、图表、chip 边框等）必须使用 `colorScheme.primary`

#### Scenario: 有品牌色

- **WHEN** 某事件的 `color` 解析成功
- **THEN** 必须使用解析后的 `Color` 作为该事件在该场景下的强调色

#### Scenario: Web 平台

- **WHEN** 运行在 Web 且不支持本地 logo 文件
- **THEN** 系统 MAY 继续使用 `Image.network(logoUrl)` 与占位 fallback，不受「禁止 network 过渡」约束

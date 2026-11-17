## ADDED Requirements

### Requirement: Tier wall SHALL dismiss without a close icon via outside tap

The fullscreen Free/Pro predict capability wall MUST NOT show a top-right close `IconButton` (or equivalent ✕). The client MUST allow dismiss by tapping the dimmed/outside region around the tier cards（or an equivalent non-card backdrop hit target）. Taps that scroll or interact inside a tier card MUST NOT dismiss solely because the dialog content is full-screen. `barrierDismissible` alone MUST NOT be treated as sufficient if the dialog child covers the entire screen without a backdrop hit target.

两档墙 MUST NOT 展示右上关闭图标；MUST 支持点遮罩/外部关闭；卡内滚动 MUST NOT 误关；全屏子树吞点击时 MUST 另设可点背景。

#### Scenario: 无右上关闭

- **WHEN** 两档墙打开
- **THEN** UI MUST NOT 显示右上角关闭图标

#### Scenario: 点外部关闭

- **WHEN** 用户点按档位卡以外的遮罩/背景区域
- **THEN** 客户端 MUST 关闭该墙

### Requirement: Tier wall bodies SHALL render Markdown without algorithm jargon on Free

The Free tier body MUST be client-authored Markdown that lists product capabilities with a leading emoji（or equivalent glyph）on each item, covering at least: next-time estimate from feeding frequency, smart push reminders, home-widget prediction, household sharing, landscape cast sharing on the prediction page, voice-ball wake for hands-free record/query, multi-day baby trend charts, and Xiaozhi speaker connection with copy that the speaker connection capability can be paid to unlock. Free copy MUST NOT include a「能做什么」-style heading, MUST NOT show unordered-list `·` markers（emoji serves as the row label）, and MUST NOT mention algorithm internals or keywords such as「亲和」. The Pro tier body MUST render the catalog item `description` as Markdown when non-empty（fallback short plain copy when empty）. Body text MUST be left-aligned in a scroll view（MUST NOT force centered paragraph layout that breaks lists）. Tier hero images MUST use a compact fixed-height contain frame（MUST NOT use a full-width large 16:10 hero）. Non-actionable footers MUST use a light gray background and black/onSurface text.

免费档 MUST 为带行首 emoji 的客户端 MD 清单（无「能做什么」标题、无列表 ·）；MUST NOT 出现亲和等算法词；Pro 档 MUST 按 MD 渲染 catalog `description`；logo MUST 小图 contain；非可点脚 MUST 浅灰底+黑字。

#### Scenario: Free 含约定能力且行首有图标

- **WHEN** 用户查看免费档
- **THEN** 正文 MUST 为 Markdown 且每条能力行首含 emoji（或等价标签图标）
- **AND** MUST 涵盖智能估算下次、推送提醒、桌面小组件、家庭共享、横向投屏、语音球、多日趋势、小智音箱可付费开通连接
- **AND** MUST NOT 展示「能做什么」类标题
- **AND** MUST NOT 展示列表前导「·」
- **AND** MUST NOT 出现「亲和」等算法关键字

#### Scenario: Pro 渲染 catalog MD

- **WHEN** `predict_capability_pro.description` 非空且含 Markdown 列表标记
- **THEN** 墙内 Pro 正文 MUST 按 Markdown 展示（非原样纯文本一行）

### Requirement: Tier logos SHALL share contain framing

Free and Pro hero images on the wall MUST use the same aspect-ratio frame and MUST use `BoxFit.contain`（or equivalent letterboxing）. The client MUST NOT use `BoxFit.cover` for the Pro network logo in a way that horizontally fills/crops differently from Free.

Free/Pro 墙头图 MUST 同框且 contain；Pro MUST NOT 用 cover 横向撑满裁切。

#### Scenario: Pro 与 Free 同 fit

- **WHEN** Pro 档展示网络 logo
- **THEN** logo MUST 使用与免费档相同的宽高比框与 contain 适配

### Requirement: Tier footers SHALL be non-button status labels this release

This release MUST NOT offer in-wall trial or payment CTAs for Pro. Footer chrome for non-actionable states MUST NOT look like a tappable button（MUST NOT use the filled/glass outlined button chrome with InkWell）. It MUST present as a status label with a **light gray** background and **black / onSurface** text（MUST NOT use tier accent for footer fill or label color）. Labels MUST be：基础版 slide always「正在使用」（including when the user already has Pro）；Pro when time-valid unlocked「正在使用」；otherwise Pro「敬请期待」. The client MUST NOT show「当前可用」on this wall. The 基础版 slide title MUST be「基础版」（MUST NOT「免费版」）.

本版墙内 MUST NOT 提供 Pro 试用/支付可点 CTA；非可点脚 MUST 为浅灰底+黑字状态标签而非按钮（MUST NOT 用档位 accent 填底/着色）；基础版恒「正在使用」；Pro 已开通「正在使用」否则「敬请期待」；MUST NOT「当前可用」；墙标题 MUST NOT「免费版」。

#### Scenario: 基础版脚恒正在使用

- **WHEN** 用户已开通 Pro 并滑到基础版档
- **THEN** 基础版档脚 MUST 显示「正在使用」且不可点、非按钮形态
- **AND** 该档标题 MUST 为「基础版」

#### Scenario: Pro 未开通敬请期待

- **WHEN** Pro 未开通
- **THEN** Pro 档脚 MUST 显示「敬请期待」且不可点、非按钮形态

#### Scenario: Pro 已开通正在使用

- **WHEN** `predict_capability_pro` 有效开通
- **THEN** Pro 档脚 MUST 显示「正在使用」且不可点、非按钮形态

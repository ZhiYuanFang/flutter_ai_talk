## ADDED Requirements

### Requirement: Theme colors SHALL be consumed via semantic atoms only

Business UI in `app/lib/ui/**` and `app/lib/ucg/**` SHALL resolve theme-dependent colors through the semantic atom API (e.g. `AppColor.*`) and/or paired fields on `AppVisualTokens`, and MUST NOT assemble fills/foregrounds by reading `isDarkShell` or hard-coding greys / high-alpha white for ordinary chrome. Documented exceptions (event brand hex, media scrims, third-party SDK) MAY remain when commented.

业务 UI **必须** 经语义原子 API / `AppVisualTokens` 成对字段取随主题色；**不得** 为拼色读取 `isDarkShell` 或硬编码灰/高 alpha 白作常规 chrome；事件色/媒体遮罩/SDK 例外须注释。

#### Scenario: 组件不判断暗壳拼色

- **WHEN** 业务 widget 需要页面底、正文或 Dialog 底色
- **THEN** 实现 MUST 调用原子 API（或读取对应 token 字段）
- **AND** MUST NOT 在该 widget 内用 `isDarkShell` 分支拼出上述颜色

#### Scenario: 事件强调色仍可注入

- **WHEN** 历史编辑玻璃面板或事件相关控件需要事件品牌色
- **THEN** MAY 使用 `eventAccent` / `colorHex` 作为强调叠色
- **AND** 正文/默认面板角色色仍 MUST 来自语义原子

### Requirement: Modal and content-card roles SHALL stay separate

The system SHALL derive distinct `modal*` and `contentCard*` (records) roles. On dark shells, modal fills MUST use surface-based dark frosted colors with `textOnModal` / shell-readable foreground, and MUST NOT pair light `contentCard` / high-luminance records fills with `onShell` white body text. Feed/history content cards MAY remain lighter with `textOnContentCard`.

系统 **必须** 区分 `modal*` 与 `contentCard*`。暗壳下 modal **必须** 为 surface 系暗浮层 + 可读浅字；**不得** 用浅 contentCard/records 底配 `onShell` 白字。Feed/历史 content 卡 MAY 保持偏亮 + 深字。

#### Scenario: 夜空下预测登录引导卡可读

- **WHEN** 用户处于夜空（或其它暗壳）且预测页展示登录或绑定引导卡
- **THEN** 卡片填充 MUST 来自 `modalFill`（或等价暗浮层原子）
- **AND** 标题与说明文字 MUST 来自 `textOnModal` / 配对前景，与底形成可读对比
- **AND** MUST NOT 呈现「近白浅蓝底 + 白字」不可读组合

#### Scenario: 夜空下 Feed 卡可仍为内容卡角色

- **WHEN** 暗壳主题下展示 UCG Feed 动态卡
- **THEN** 卡片底 MUST 使用 `contentCard`（或既有 records 语义），正文 MUST 使用 `textOnContentCard`
- **AND** MUST NOT 因此被迫与 modal 使用同一浅/暗策略

### Requirement: Shared dialog chrome SHALL use modal atoms

Centered glass dialogs entered via `showGlassDialog` / confirm helpers, and soft-gate overlays that present login/bind/onboarding prompts on the prediction hub, SHALL paint panel fill, border, and default label colors from `modal*` atoms (or a shared panel widget bound to those atoms).

经 `showGlassDialog`/确认 helper 的居中玻璃 Dialog，以及预测页登录/绑定/引导软浮层，面板底、边与默认文案色 **必须** 来自 `modal*` 原子（或绑定该原子的共享 panel）。

#### Scenario: 确认 Dialog 与引导卡同源底色角色

- **WHEN** 同一暗壳主题下分别打开玻璃确认 Dialog 与预测绑定引导卡
- **THEN** 两者面板填充角色 MUST 同为 `modalFill`（允许布局不同）
- **AND** 默认标题/正文前景角色 MUST 同为 `textOnModal`（或等价配对）

### Requirement: Atom catalog SHALL cover page, text, field, primary, barrier

`VisualBundle.toTokens()` (or equivalent single derivation point) SHALL populate at least: page background, primary/secondary/muted text on shell, surface pair, content-card pair, modal pair (fill/border/on), field fill/border, primary/onPrimary, divider, and barrier. Alpha used for muted/glass MUST be defined inside derivation, not required as per-call theme algorithm knobs from business widgets.

派生点 **必须** 至少填充：页面底、壳上主/次/弱字、surface 对、contentCard 对、modal 对、field、primary/onPrimary、divider、barrier。弱化/玻璃所用 α **必须** 定义在派生内，**不得** 要求业务每次传入作为主题算法。

#### Scenario: 切换夜空后原子一次性更新

- **WHEN** 用户将主题切换为夜空
- **THEN** `pageBg`、`textPrimary`、`modalFill`、`textOnModal`、`contentCard` 等原子 MUST 随新 bundle 更新
- **AND** 已挂载且正确消费原子的页面 MUST 无需各组件本地分支即可反映新主题

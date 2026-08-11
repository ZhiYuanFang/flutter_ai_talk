## ADDED Requirements

### Requirement: 登录与绑定门闸 MUST NOT 在进入预测页时自动展示

When the user opens the smart prediction page while not logged in, or while logged in but unbound, the client MUST NOT automatically present the login or bind gate Dialog solely due to page entry. The applicable gate Dialog MUST open only after an intentional trigger: tapping a demo-skeleton prediction event card, or an explicit login/bind CTA control (the gate Dialog primary button counts only after the Dialog is already shown). Blank-area taps, scroll gestures, and layout-toggle taps MUST NOT open the login or bind gate. Soft dismiss MUST still close the Dialog without permanently suppressing future intentional opens. Navigation to `/login` or `/settings/bind-baby` MUST remain on the gate Dialog primary CTA (or equivalent explicit CTA), not on skeleton card tap alone. Recall onboarding auto-show behavior is out of scope for this requirement.

未登录或已登录未绑定进入智能预测页时，客户端 **不得** 仅因进页自动展示登录或绑定门闸 Dialog。适用门闸 **必须** 仅在意图触发后打开：点击冷态骨架预测事件卡，或明确的登录/绑定 CTA（门闸主按钮仅在 Dialog 已展示后计）。空白区点击、滑动、布局切换 **不得** 打开登录/绑定门闸。软关仍关闭 Dialog 且 **不得** 永久禁止后续意图打开。进入 `/login` 或 `/settings/bind-baby` **必须** 仍由门闸主按钮（或等价明确 CTA）触发，**不得** 仅因骨架卡点击。量身定做自动展示不在本需求范围。

#### Scenario: 未登录进页不自动弹登录门闸

- **WHEN** 用户未登录并进入智能预测页
- **THEN** UI MUST NOT 自动展示登录引导 Dialog
- **AND** 底层 MUST 仍为冷态骨架

#### Scenario: 已登录未绑定进页不自动弹绑定门闸

- **WHEN** 用户已登录、无可用 deviceNo，进入智能预测页
- **THEN** UI MUST NOT 自动展示绑定宝宝引导 Dialog
- **AND** 底层 MUST 仍为冷态骨架

#### Scenario: 未登录点骨架卡打开登录门闸

- **WHEN** 用户未登录、登录门闸尚未可见，冷态骨架展示中
- **AND** 用户点击某一预测事件卡片
- **THEN** 客户端 MUST 展示登录引导 Dialog
- **AND** MUST NOT 仅因该点击导航至 `/login`

#### Scenario: 已登录未绑定点骨架卡打开绑定门闸

- **WHEN** 用户已登录、无可用 deviceNo、绑定门闸尚未可见，冷态骨架展示中
- **AND** 用户点击某一预测事件卡片
- **THEN** 客户端 MUST 展示绑定宝宝引导 Dialog
- **AND** MUST NOT 仅因该点击导航至 `/settings/bind-baby`

#### Scenario: 空白点击不打开登录或绑定门闸

- **WHEN** 用户未登录或已登录未绑定，门闸未可见
- **AND** 用户点击预测页空白/非骨架卡区域（非明确登录/绑定 CTA）
- **THEN** 客户端 MUST NOT 因此打开登录或绑定引导 Dialog

#### Scenario: 切布局不打开登录或绑定门闸

- **WHEN** 用户未登录或已登录未绑定，门闸未可见
- **AND** 用户点击布局切换按钮
- **THEN** 客户端 MUST NOT 因此打开登录或绑定引导 Dialog

#### Scenario: 门闸 CTA 仍可去登录

- **WHEN** 登录引导 Dialog 可见且用户点击其主按钮
- **THEN** 客户端 MUST 导航至 `/login`（或等价）

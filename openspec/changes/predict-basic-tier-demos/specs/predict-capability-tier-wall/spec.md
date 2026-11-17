## ADDED Requirements

### Requirement: Basic-tier wall body SHALL show mid-fidelity code-drawn demos per capability

On the 基础版（client free-tier）slide of the predict capability wall, the client MUST NOT rely solely on a single Markdown document for the capability list. The client MUST render an ordered list of capability rows. Each row MUST include: a leading emoji（or equivalent）, a title, a short subtitle matching the product copy for that capability, and a **below-text** mid-fidelity illustrative demo built from Flutter widgets / `CustomPaint`（no external image assets required for these demos）. Demos MUST use fixed fake data, MUST NOT be tappable for navigation or business actions, and MUST NOT read live prediction/history providers solely to populate the demo. The eight capabilities MUST include at least: next-time estimate, smart push reminder, home widget, household sharing, landscape cast sharing, voice-ball wake, multi-day trend chart, and Xiaozhi speaker（with paid-unlock hint）. The Pro slide MAY continue to render catalog Markdown without these demos.

基础版墙 MUST 以结构化条目展示能力，每条含 emoji、标题、短说明及文案下方的中档代码绘制 demo（假数据、不可点、不拉真预测数据）；八条能力 MUST 齐；Pro 档 MAY 仍仅 MD。

#### Scenario: 每条含下方 demo

- **WHEN** 用户打开两档墙并查看基础版
- **THEN** 每个能力条目下方 MUST 出现不可点的示意控件（非空白占位）
- **AND** MUST NOT 仅靠 Markdown 列表而无 demo

#### Scenario: demo 不驱动业务

- **WHEN** 用户点按某条能力的 demo 区域
- **THEN** 客户端 MUST NOT 因此导航、开通、或写入喂养/预测状态

#### Scenario: 八条能力齐全

- **WHEN** 基础版正文渲染完成
- **THEN** 列表 MUST 含智能估算下次、推送提醒、桌面小组件、家庭共享、横向投屏、语音球、多日趋势、小智音箱（可付费开通提示）对应条目与 demo

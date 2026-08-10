## ADDED Requirements

### Requirement: Prediction tip SHALL be a bottom fixed horizontal marquee without tip chrome labels

The smart prediction page SHALL render the widget tip text (when non-empty) as a **bottom-fixed** bar whose content is a **horizontal** marquee of the tip body only. The bar MUST NOT display the labels「小贴士」or「点击进入陪伴」(or equivalent chrome). When tip text is null or empty, the page MUST hide the entire bottom tip bar. The tip MUST NOT appear between the title and the care-alert / event card regions.

智能预测页有 tip 文案时 **必须** 以底部固定条展示，内容为正文横向跑马灯；**不得** 展示「小贴士」「点击进入陪伴」；无文案时 **必须** 隐藏整条；tip **不得** 再出现在标题与留意/卡片区之间。

#### Scenario: 底栏仅正文

- **WHEN** tip 文案非空且用户打开智能预测页
- **THEN** 页面底部 MUST 出现 tip 条
- **AND** 条内 MUST 展示 tip 正文
- **AND** MUST NOT 展示「小贴士」或「点击进入陪伴」字样
- **AND** 标题与值得留意/卡片区之间 MUST NOT 再出现原顶 tip 卡

#### Scenario: 无 tip 隐藏

- **WHEN** tip 文案为空或 null
- **THEN** 页面 MUST NOT 渲染底部 tip 条占位

### Requirement: Tip marquee SHALL stay static when text fits the viewport

When the tip body text’s laid-out width is less than or equal to the tip bar’s visible content width, the client MUST keep the text static (MUST NOT idle-scroll). When the text overflows that width, the client MUST scroll it horizontally so the full text can be read over time.

tip 正文宽度 ≤ 可视内容宽度时 **必须** 静止；溢出时 **必须** 横向滚动以完整可读。

#### Scenario: 短文静止

- **WHEN** tip 正文在当前底栏宽度下不溢出
- **THEN** 客户端 MUST 静止展示该文案
- **AND** MUST NOT 启动横向空转滚动

#### Scenario: 长文横向滚

- **WHEN** tip 正文宽度超过底栏可视内容宽度
- **THEN** 客户端 MUST 横向滚动展示完整文案

### Requirement: Tapping the bottom tip bar SHALL open companion chat

Tapping the bottom tip bar SHALL activate companion Clinic entry as today and navigate to the companion chat route (`/companion` or equivalent). The absence of「点击进入陪伴」copy MUST NOT remove this tap affordance.

点击底部 tip 条 **必须** 进入陪伴聊天；去掉 CTA 文案 **不得** 取消可点进聊天的能力。

#### Scenario: 点底栏进陪伴

- **WHEN** 底部 tip 条可见且用户点击该条
- **THEN** 客户端 MUST 导航至陪伴聊天页

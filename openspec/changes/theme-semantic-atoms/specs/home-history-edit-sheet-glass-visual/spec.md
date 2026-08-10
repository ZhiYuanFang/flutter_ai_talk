## MODIFIED Requirements

### Requirement: 玻璃拟态编辑卡片容器

The client SHALL present the home history edit sheet content inside a glassmorphism-style panel with background blur, semi-transparent fill, rounded corners, and a subtle luminous border, with fill/border/default label colors taken from theme semantic modal/sheet atoms (not hard-coded single hex boards). 编辑 Sheet 主体 MUST 使用**磨砂玻璃**效果（背景模糊 + 半透明填充 + 圆角 + 微光描边），与参考稿一致的卡片式弹层，而非默认 Material 纯色 bottom sheet 面板；面板底、描边与默认文案色 MUST 来自主题语义 `modal*`/`sheet*` 原子（或等价 token），**不得**写死单一深色/浅色 hex 作为唯一底板或唯一正文色；事件 accent MAY 仅参与渐变强调。

#### Scenario: 打开编辑 Sheet

- **WHEN** 用户点击一条可编辑历史记录
- **THEN** 客户端 MUST 在半透明遮罩上展示玻璃质感圆角卡片容器，且卡片内承载全部编辑控件

#### Scenario: 明暗主题

- **WHEN** 用户切换 shell 明暗主题后打开编辑 Sheet
- **THEN** 玻璃容器与文字 MUST 仍保持可读对比度，且继续使用主题语义色（非写死单一 hex）

#### Scenario: 夜空下编辑玻璃跟 modal 原子

- **WHEN** 夜空或其它暗壳主题下打开历史编辑玻璃 Sheet
- **THEN** 面板填充与默认前景 MUST 来自 `sheet*`/`modal*` 语义原子
- **AND** MUST NOT 依赖与当前主题无关的固定 `#1A2428` / `#F3F5F7` 等硬编码作为唯一方案

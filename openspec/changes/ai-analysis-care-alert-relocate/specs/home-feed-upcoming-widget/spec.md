## ADDED Requirements

### Requirement: Home widget MUST NOT display tip copy

Home-widget sync and native rendering MUST NOT present feeding tip / care-alert-derived tip text on medium or large widgets. Flutter MUST NOT populate a user-visible tip section in the widget payload for display, and MUST NOT call care-alert daily fetch for the purpose of deriving widget tip. Native tip sections MUST remain hidden when absent or empty. 桌面小组件 sync 与 native **不得** 展示 tip 文案；Flutter **不得** 为展示填充 tip，且 **不得** 为派生 tip 调用 care-alert daily；无 tip 时 native tip 区 **必须** 隐藏。

#### Scenario: sync 不推 tip

- **WHEN** 客户端执行桌面小组件同步且预测数据就绪
- **THEN** 推送的 payload MUST NOT 含有用于展示的非空 tip 文案
- **AND** MUST NOT 因此请求 care-alert daily

#### Scenario: native 隐藏 tip 区

- **WHEN** medium 或 large 小组件收到无 tip 或空 tip 的 payload
- **THEN** native MUST 隐藏 tip 区块（visibility gone 或等价）

### Requirement: Large widget recent candidates SHALL allow up to six in two rows

For the large home widget, the client SHALL include up to six recent-candidate rows in the payload (hero event still excluded from recent as today), and native large layout MUST render them as two horizontal rows of up to three slots each. Medium widgets MUST remain capped at three recent slots and MUST NOT gain a second row from this change. 大尺寸小组件 payload **必须** 最多含 6 条 recent（仍排除 hero）；native large **必须** 两行×最多三槽渲染；medium **必须** 仍最多 3 且不加第二行。

#### Scenario: large 两行六槽

- **WHEN** large 小组件 payload 含 6 条 recent（已排除 hero）
- **THEN** native MUST 展示两行，每行最多 3 个候选槽
- **AND** 六个候选 MUST 均可绑定展示（在数据充足时）

#### Scenario: large 不足六条

- **WHEN** recent 仅有 4 条
- **THEN** native MUST 展示已有条目并隐藏空余槽位
- **AND** MUST NOT 伪造占位事件

#### Scenario: medium 仍为三

- **WHEN** medium 小组件刷新
- **THEN** recent 展示上限 MUST 仍为 3
- **AND** MUST NOT 出现第二行 recent 槽

## MODIFIED Requirements

### Requirement: Widget rows SHALL prioritize active timing then global nextAt

Content row budget MUST be: small=1, medium=3, large hero plus up to 6 recent candidates (two rows × 3) for the v3 large recent section. Active timing / hero prioritization rules already defined for the widget remain in force for hero selection. Predict/recent rows for large MUST be chosen consistently with existing prediction ordering, excluding the current hero event id from the recent list. 行预算：small=1，medium=3，large 为 hero + 最多 6 条 recent（两行×3）；hero 选取规则保持；large recent **必须** 排除当前 hero eventId。

#### Scenario: large recent 最多六条

- **WHEN** 可预测事件（排除 hero）不少于 6 个
- **THEN** large payload recent MUST 至多 6 条
- **AND** native large MUST 按两行布局展示

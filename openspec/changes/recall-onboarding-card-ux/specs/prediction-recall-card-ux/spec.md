## ADDED Requirements

### Requirement: Recall thinking completion SHALL auto-advance to the next card

After the user confirms a prediction-recall onboarding card and the thinking typewriter finishes rendering its full copy, the client MUST automatically advance to the next root card or the finale page within a short delay (approximately 400ms) without requiring a separate「继续」tap. While typing is in progress, the user MAY skip the animation; after the full text is shown, advance MUST still occur automatically under the same rule.

用户确认量身定做单卡且思考打字机播完全文后，客户端 **必须** 在短延迟（约 400ms）内自动进入下一根事件卡或收尾页，**不得**依赖另点「继续」。打字中 **可** 跳过动画；全文展示后 **必须** 仍按同一规则自动前进。

#### Scenario: 思考播完自动下一卡

- **WHEN** 思考文案已全部展示且当前不是收尾页
- **THEN** 在约 400ms 内客户端 MUST 自动切换到下一页（下一根或收尾）

#### Scenario: 跳过动画后仍自动前进

- **WHEN** 用户在打字未完成时跳过动画使全文立刻显示
- **THEN** 客户端 MUST 仍自动前进到下一页（不得永久停在思考盖层）

### Requirement: Recall card SHALL show child events as read-only containment

On each prediction-recall onboarding root card, when the catalog has one or more real child events under that root, the client MUST show a read-only section titled to the effect of「该事件包含」listing those child names, and MUST NOT require the user to select a specific child. When the root has no children, that section MUST NOT be shown. The recall seed written on confirm MUST use the root event id as `leafEventId` (MUST NOT depend on a user-selected leaf).

量身定做根卡片在存在真实子事件时 **必须** 只读展示「该事件包含」及子事件名，**不得** 强制用户选择某一种；无子事件时 **不得** 展示该区块；确认写入种子时 `leafEventId` **必须** 为根事件 id。

#### Scenario: 有子事件只读展示

- **WHEN** 当前根在目录中有至少一个子事件
- **THEN** 卡片 MUST 展示「该事件包含」及子事件名称，且 MUST NOT 提供可选中态

#### Scenario: 无子事件隐藏

- **WHEN** 当前根没有子事件
- **THEN** UI MUST NOT 展示「该事件包含 / 当时是哪一种」区块

### Requirement: Recall card SHALL show event logo and event-tinted glass

Each prediction-recall onboarding event card MUST show the root event’s logo to the left of the event name, and MUST tint the floating card glass using that event’s brand color (`resolveEventColor` or equivalent) via the modal glass `eventAccent` path, rather than only the theme primary.

量身定做事件卡 **必须** 在事件名左侧展示根事件 logo，且浮卡玻璃 **必须** 以该事件品牌色作 accent 渐变，**不得** 仅用主题 primary。

#### Scenario: logo 与事件色

- **WHEN** 渲染某一根事件的量身定做卡片
- **THEN** 标题行 MUST 含该事件 logo，且卡片外壳 MUST 使用该事件色 accent

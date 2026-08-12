## ADDED Requirements

### Requirement: 预测横屏瀑布流 MUST 保留上边距

When the smart prediction page renders the landscape event waterfall/grid, the client MUST apply a non-zero top content padding so the first card row is not flush against the physical top edge under immersive mode. The top padding SHOULD align visually with the landscape identity rail top inset (approximately 12 logical pixels). Portrait layout padding rules MAY remain unchanged. 智能预测页横屏渲染事件瀑布流/网格时，客户端 MUST 施加非零顶部内容边距，使第一行卡片在沉浸模式下不贴齐物理顶边；顶部边距 SHOULD 与横屏身份栏上内边距视觉对齐（约 12 逻辑像素）。竖屏边距规则 MAY 保持不变。

#### Scenario: 横屏第一行不贴顶

- **WHEN** 用户在智能预测页且设备为横屏并展示事件网格
- **THEN** 第一行卡片顶部与屏幕物理顶边之间 MUST 存在可见空隙（非零 top padding）

#### Scenario: 竖屏不受本需求强制

- **WHEN** 用户在智能预测页竖屏展示瀑布流
- **THEN** 本需求 MUST NOT 要求改变既有竖屏 top padding 契约

### Requirement: 冷态骨架 MUST 在事件列表上方标注虚拟举例

When the smart prediction page uses the demo skeleton (`useDemoSkeleton`: not logged in, not bound, or bound with empty history), the client MUST show a centered banner above the prediction event list/grid with primary text「虚拟事件举例」and secondary text「请右滑补充喂养记录」. The banner MUST appear in both portrait and landscape. When the swipe-guide card is also shown (auth guest chrome), the banner MUST coexist with it (not replace it). When not using the demo skeleton, the banner MUST NOT be shown. 智能预测页使用冷态骨架（`useDemoSkeleton`：未登录、未绑定或已绑定空历史）时，客户端 MUST 在预测事件列表/网格上方居中展示主文「虚拟事件举例」与副文「请右滑补充喂养记录」；竖屏与横屏 MUST 均展示；若同时展示滑动引导大卡，横幅 MUST 与大卡并存；非骨架态 MUST NOT 展示该横幅。

#### Scenario: 未登录骨架显示虚拟举例

- **WHEN** 用户未登录进入智能预测页（`useDemoSkeleton`）
- **THEN** 事件列表上方 MUST 居中显示「虚拟事件举例」与「请右滑补充喂养记录」，且滑动引导大卡仍可展示

#### Scenario: 横屏骨架同步

- **WHEN** 用户在智能预测页横屏且处于 `useDemoSkeleton`
- **THEN** 右侧事件网格上方 MUST 同样显示上述两行文案

#### Scenario: 热态不展示

- **WHEN** 用户已登录已绑定且非空历史（非 `useDemoSkeleton`）
- **THEN** MUST NOT 显示「虚拟事件举例」横幅

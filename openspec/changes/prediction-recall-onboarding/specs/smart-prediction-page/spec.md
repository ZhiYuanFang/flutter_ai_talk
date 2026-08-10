## ADDED Requirements

### Requirement: Smart prediction empty gap state SHALL host recall onboarding

While root-event prediction gaps exist, the smart prediction page main content area SHALL host the recall onboarding PageView (floating cards) as specified by `prediction-recall-onboarding`. After the user completes the finale CTA, the page SHALL show the normal prediction list/grid (and related chrome) using history merged with any remaining seeds.

存在根事件推演缺口时，智能预测主内容区 **必须** 承载量身定做 PageView；用户完成收尾 CTA 后 **必须** 展示合并种子后的正常预测列表/瀑布流。

#### Scenario: 缺口时主区为引导

- **WHEN** 智能预测页检测到至少一个根事件缺口且引导未结束
- **THEN** 主内容区 MUST 展示量身定做悬浮卡流程
- **AND** MUST NOT 仅以无 CTA 的「暂无可用预测数据」作为唯一空态

#### Scenario: CTA 后正常预测

- **WHEN** 用户已点击收尾 CTA 且种子/历史已可驱动至少部分预测
- **THEN** 页面 MUST 展示正常智能预测卡片列表或瀑布流（及既有顶栏等 chrome）

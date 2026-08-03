## MODIFIED Requirements

### Requirement: Swipe into companion SHALL carry unconsumed done tip

When the user enters the companion page by horizontal swipe (or `homePagerRequestProvider` / tip「对话」) and an unconsumed `done` tip exists, the client MUST apply the same tip injection rules as dialog-button navigation. 用户经横滑或 tip「对话」/ pager 请求进入陪伴且存在未消费 done tip 时，**必须** 与对话按钮相同地注入 tip（**不得** 再依赖左缘拉条）。

#### Scenario: 横滑进陪伴带 tip

- **WHEN** 喂养页存在未消费 done tip，用户横滑进入陪伴页
- **THEN** 陪伴会话 MUST 注入该 tip 文本并标记消费

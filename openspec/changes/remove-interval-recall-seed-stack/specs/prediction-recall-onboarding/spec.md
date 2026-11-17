## MODIFIED Requirements

### Requirement: Bound empty history MUST NOT auto-present recall onboarding Dialog

When the user is bound and prediction-range real history is empty (or any other gap condition), the client MUST NOT automatically present the量身定做 / recall onboarding Dialog, soft-reopen it after mask dismiss, or reopen it from an empty-state「回忆宝宝习惯」control. Fill flows MUST use hot catalog-complete prediction cards with「补充上一次」(and appointment「补充下次」where applicable) and MUST NOT rely on「补充大概多久一次」or recall-seed interval entry. 已绑定且预测 range 真历史为空（或其它缺口）时，客户端 MUST NOT 自动展示量身定做 Dialog，MUST NOT 遮罩软关后再弹，MUST NOT 经空态「回忆宝宝习惯」重开。补齐 MUST 走热态卡「补充上一次」（预约则「补充下次」），MUST NOT 依赖「补充大概多久一次」或回忆种子入口。

#### Scenario: 空库不弹 Dialog

- **WHEN** 用户已绑定、range 就绪且真历史为空，进入智能预测页
- **THEN** UI MUST NOT 自动展示量身定做 Dialog
- **AND** MUST 展示目录完备热态预测卡

#### Scenario: 无空态再开

- **WHEN** 用户在空历史热态预测页操作
- **THEN** 客户端 MUST NOT 提供仅用于重开量身定做 Dialog 的「回忆宝宝习惯」主空态 CTA

#### Scenario: 补齐不走间隔种子

- **WHEN** 热态卡需要用户补齐缺口
- **THEN** UI MAY 展示「补充上一次」或预约「补充下次」
- **AND** MUST NOT 展示「补充大概多久一次」

## ADDED Requirements

### Requirement: Recall onboarding MUST NOT write interval seeds

If any residual recall-onboarding UI remains reachable, it MUST NOT upsert `PredictionRecallSeed` or present「大概多久一次」as a seed-writing control. Prefer deleting unreachable onboarding panel code. 若仍有可达的量身定做 UI，MUST NOT upsert 回忆种子，MUST NOT 展示写种子的「大概多久一次」。不可达代码优先删除。

#### Scenario: 无写种子控件

- **WHEN** 审计客户端预测相关 UI
- **THEN** MUST NOT 存在确认后写入 `PredictionRecallSeed` 的「大概多久一次」控件

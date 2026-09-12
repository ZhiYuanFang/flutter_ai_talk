## ADDED Requirements

### Requirement: Bound empty history MUST NOT auto-present recall onboarding Dialog

When the user is bound and prediction-range real history is empty (or any other gap condition), the client MUST NOT automatically present the量身定做 / recall onboarding Dialog, soft-reopen it after mask dismiss, or reopen it from an empty-state「回忆宝宝习惯」control. Fill flows MUST use hot catalog-complete prediction cards（补充上一次 / 补充大概多久一次）instead.

已绑定且预测 range 真历史为空（或其它缺口条件）时，客户端 **不得** 自动展示量身定做 / 回忆引导 Dialog，**不得** 在遮罩软关后自动再弹，**不得** 经由空态「回忆宝宝习惯」控件再打开该 Dialog。补齐 **必须** 改走热态目录完备预测卡上的「补充上一次」/「补充大概多久一次」。

#### Scenario: 空库不弹 Dialog

- **WHEN** 用户已绑定、range 就绪且真历史为空，进入智能预测页
- **THEN** UI MUST NOT 自动展示量身定做 Dialog
- **AND** MUST 展示目录完备热态预测卡

#### Scenario: 无空态再开

- **WHEN** 用户在空历史热态预测页操作
- **THEN** 客户端 MUST NOT 提供仅用于重开量身定做 Dialog 的「回忆宝宝习惯」主空态 CTA

## REMOVED Requirements

### Requirement: Prediction page SHALL show recall cards for root event gaps

**Reason**：空库量身定做 Dialog / 队列引导退役；缺口改为卡内补齐。

**Migration**：见 `smart-prediction-page` 目录完备行与「补充上一次」/间隔 CTA；本能力不再要求进入预测页即弹引导。

### Requirement: Recall onboarding SHALL use a non-swipeable floating card PageView

**Reason**：Dialog + PageView 主表面随自动引导一并退役。

**Migration**：无需迁移用户数据；面板实现可保留死代码直至清理任务删除。

### Requirement: Recall Dialog SHALL soft-dismiss on barrier and reopen except avatar

**Reason**：不再存在可软关再弹的量身定做 Dialog。

**Migration**：无。

### Requirement: Completing recall onboarding SHALL permanently suppress the Dialog

**Reason**：Dialog 自动路径退役后无需 finale 永久抑制。

**Migration**：相关 `predictionRecallFinaleDismissed` 门闸可随入口拆除一并停用。

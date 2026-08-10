## MODIFIED Requirements

### Requirement: Prediction page SHALL show recall cards for root event gaps

When the user opens the smart prediction page, the client SHALL show recall onboarding **only if** the user is bound (usable deviceNo) **and** the prediction-range real history is completely empty (no records) after the range load is ready **and** the onboarding finale has not been permanently dismissed. If any real history record exists in that source, the client MUST NOT show the onboarding and MUST rely on real data only for prediction. When onboarding is shown, the queue SHALL still cover catalog root events (`parentId == null`) that are not forecast-disabled. Roots the user has skipped (forecast disabled) MUST NOT re-enter the queue until forecast is re-enabled. Unauthenticated or unbound users MUST NOT see recall onboarding (they see the demo skeleton only).

进入智能预测页时，客户端 **仅当** 已绑定、预测 range 真历史就绪后完全为空、且量身定做未永久收尾时才展示引导；有任意真历史则 **不得** 引导；未登录/未绑定 **不得** 展示量身定做。展示时队列仍覆盖未关推演的根；已跳过关推演的根 **不得** 再入队。

#### Scenario: 完全无记录才引导

- **WHEN** 用户已绑定、预测 range 已就绪且 items 为空、且未永久收尾，进入智能预测页
- **THEN** UI MUST 展示量身定做引导（Dialog + PageView）

#### Scenario: 有任意真历史不引导

- **WHEN** 预测 range 中存在至少一条真历史记录
- **THEN** UI MUST NOT 展示量身定做引导
- **AND** MUST 按正常预测逻辑仅使用真历史（及既有非引导路径）

#### Scenario: range 未就绪不误开

- **WHEN** 预测 range 仍在首次加载、尚未 ready
- **THEN** 客户端 MUST NOT 仅因「暂时空列表」启动量身定做会话

#### Scenario: 未绑定不引导

- **WHEN** 用户未登录或无可用 deviceNo
- **THEN** UI MUST NOT 展示量身定做 Dialog

### Requirement: Recall onboarding SHALL use a non-swipeable floating card PageView

The onboarding main surface SHALL be a modal Dialog over the smart prediction page whose content is a PageView of floating-style cards (one logical step per page). The underlying page MUST continue to show the demo skeleton (and cold care-alert placeholder) while the Dialog is open. The PageView MUST use non-scrollable physics so the user cannot change pages by horizontal drag. Page changes MUST occur only via programmatic navigation after confirm, skip, thinking continue, or equivalent controls.

量身定做主表面 **必须** 为叠在预测页上的 Dialog，内含悬浮感卡片 PageView；Dialog 打开时底层 **必须** 仍为骨架（及冷态留意占位）；PageView **必须** 禁手滑；切页 **必须** 仅由控件程序驱动。

#### Scenario: 禁手滑

- **WHEN** 用户在量身定做卡片上左右拖滑
- **THEN** PageView MUST NOT 切换到另一张卡片

#### Scenario: 确认后程序前进

- **WHEN** 用户确认当前根事件卡片
- **THEN** 客户端 MUST 程序切换到该卡思考页或下一流程页（不得依赖用户手滑）

#### Scenario: Dialog 底层为骨架

- **WHEN** 量身定做 Dialog 正在展示
- **THEN** Dialog 下方的预测主内容 MUST 仍为冷态骨架行（非空白占满引导）

## ADDED Requirements

### Requirement: Recall Dialog SHALL soft-dismiss on barrier and reopen except avatar

The recall Dialog MUST be dismissible by tapping the scrim/barrier (soft dismiss). Soft dismiss MUST NOT mark the onboarding as permanently finished. After a soft dismiss, tapping any interactive region of the smart prediction page **except** the header baby avatar MUST reopen the Dialog until the onboarding is permanently finished. Tapping the avatar MUST navigate to settings and MUST NOT reopen the Dialog as the tap’s primary action.

量身定做 Dialog **必须** 可点遮罩软关；软关 **不得** 视为永久结束；软关后除顶栏头像外点击预测页区域 **必须** 再弹 Dialog，直至永久收尾；点击头像 **必须** 进入设置且 **不得** 以再弹 Dialog 为该次点击主行为。

#### Scenario: 点遮罩软关

- **WHEN** 量身定做 Dialog 打开且用户点击外部遮罩
- **THEN** Dialog MUST 关闭
- **AND** 客户端 MUST NOT 将会话标记为永久收尾

#### Scenario: 软关后非头像再弹

- **WHEN** 量身定做已软关且尚未永久收尾，用户点击预测页非头像区域
- **THEN** 客户端 MUST 再次展示量身定做 Dialog

#### Scenario: 软关后点头像进设置

- **WHEN** 量身定做已软关且尚未永久收尾，用户点击预测顶栏头像
- **THEN** 客户端 MUST 导航至设置页
- **AND** MUST NOT 仅因该点击重新打开量身定做 Dialog

### Requirement: Completing recall onboarding SHALL permanently suppress the Dialog

When the user finishes the recall onboarding finale (or equivalent completion path that ends the guided sampling), the client SHALL mark onboarding permanently dismissed for the current empty-history episode and MUST NOT reopen the Dialog via soft-dismiss reopen gestures. Permanent dismiss MUST NOT remove the underlying demo skeleton until real history appears.

用户完成量身定做收尾后，客户端 **必须** 永久抑制 Dialog 再弹；永久关闭 **不得** 在真历史出现前移除底层骨架。

#### Scenario: 走完不再弹

- **WHEN** 用户完成量身定做收尾 CTA
- **THEN** 客户端 MUST 关闭 Dialog
- **AND** 此后点击预测页非头像区域 MUST NOT 再打开量身定做 Dialog
- **AND** 主内容 MUST 仍为骨架直至出现真历史

### Requirement: Childless root recall card SHALL show only the root control

When a catalog root event has no child events, the recall card for that root SHALL present only a single control for the root itself (MUST NOT present an empty multi-leaf chooser).

无子节点的根事件回忆卡 **必须** 仅展示根自身一钮。

#### Scenario: 无子根单钮

- **WHEN** 当前量身定做卡片对应的根在目录中无子事件
- **THEN** UI MUST 仅展示该根自身的一个选择控件

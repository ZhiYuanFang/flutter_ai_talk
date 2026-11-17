## REMOVED Requirements

### Requirement: Algo-ready dialog SHALL await entitlement settle before showing

**Reason**: 免费亲和单轨后算法就绪弹窗已空转（默认不再展示）；继续保留 Host / store / silentAffinity 门闸只会误导维护。

**Migration**: 删除 `_PredictAlgoReadyHost`、`maybeShowPredictAlgoReadyOnboarding`、`PredictAlgoReadyDialogResult`、`silentAffinityReady` / `rootAffinityReadyWithoutSeed`；试用成功仍用 `showPredictBasicTrialSuccessDialog`。

## ADDED Requirements

### Requirement: Predict trial success dialog SHALL NOT direct users to unlock hub

When the client shows the predict capability trial-success confirmation glass dialog, the body copy MUST NOT tell the user to check expiry in the feature unlock hub（「开通中心」）or navigate there. The dialog MAY state that Pro（or the granted tier）is active for about N days and MUST offer a dismiss action.

试用成功确认 MUST NOT 引导去开通中心查看到期；MAY 说明约 N 天有效；MUST 可关闭。

#### Scenario: 成功文案无开通中心

- **WHEN** 用户墙内试用成功并展示确认弹窗
- **THEN** 正文 MUST NOT 出现「开通中心」或等价引导用户打开已退休 Hub 的表述
- **AND** MUST 仍展示可关闭的确认（如「好的」）

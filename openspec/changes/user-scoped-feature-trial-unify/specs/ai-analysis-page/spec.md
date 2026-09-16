## ADDED Requirements

### Requirement: Unqualified feeding hub card SHALL confirm before navigating to feeding
When feeding eligibility is not qualified, tapping the AI Hub「喂养记录分析」card SHALL show a confirm dialog explaining the need to record feeding; only after the user confirms SHALL the client navigate to the home feeding page. It MUST NOT jump immediately on tap. 未达标点击喂养分析卡 **必须** 先弹窗确认，**不得** 直接跳喂养。

#### Scenario: Tap shows dialog
- **WHEN** 喂养未达标用户点击 Hub 喂养记录分析卡
- **THEN** MUST 弹出提示；在用户确认前 MUST NOT `go` 喂养页

#### Scenario: Confirm navigates
- **WHEN** 用户在该弹窗确认前往喂养
- **THEN** 客户端 MUST 进入首页喂养页

#### Scenario: Cancel stays
- **WHEN** 用户取消弹窗
- **THEN** MUST 留在 AI 分析 Hub

### Requirement: Locked capability dialog SHALL introduce feature and pay without invite field
When care is feeding-qualified but locked, or growth is locked, the unlock dialog SHALL show a normal feature introduction **without** an invite-code text field. The primary button MUST display the payment amount and start payment on tap. A secondary action「其它方式开通」MUST navigate to `/features/unlock`. 未开通弹窗 **必须** 为功能介绍+标价支付，**不得** 含邀请输入框；其它方式进开通中心。

#### Scenario: Care locked dialog
- **WHEN** 喂养已达标且 care 未开通，用户点击 Hub 喂养卡或等价开通入口
- **THEN** 弹窗 MUST 无邀请输入框；主按钮 MUST 含支付金额并可拉起支付；「其它方式开通」MUST 进入 `/features/unlock`

#### Scenario: Growth locked dialog
- **WHEN** growth 未开通，用户点击 Hub 成长卡或详情内开通 CTA
- **THEN** 行为 MUST 与上条同构（功能介绍、标价支付、其它方式进开通中心）

### Requirement: Feeding analysis CTA SHALL sit below body content centered
On the feeding analysis detail screen, the「AI智能分析」control and its explanatory caption SHALL be placed below the main body content and horizontally centered, not in the AppBar trailing actions. 喂养分析详情的分析按钮与说明 **必须** 在正文下方横向居中。

#### Scenario: Layout
- **WHEN** 用户打开喂养记录分析详情且具备可分析条件（已开通或 soft trial 等）
- **THEN**「AI智能分析」与说明文案 MUST 出现在正文下方居中区域，MUST NOT 作为 AppBar 右上角主入口

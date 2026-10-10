## ADDED Requirements

### Requirement: 永久开通支付前须确认不含硬件

Before the client creates a permanent unlock order or launches platform payment for Xiaozhi MCP, it MUST show a dismissible confirmation stating that the user must purchase the Xiaozhi speaker hardware separately and that this payment does not include the physical speaker. If the user cancels or dismisses the confirmation, the client MUST NOT create an order or launch payment. 永久开通调起建单/支付前 **必须** 二次确认「须自行购机、付款不含实体」；用户取消则 **不得** 进入支付。

#### Scenario: 主 CTA 确认后支付

- **WHEN** 用户在可售且未永久开通状态下点击「永久开通」并确认硬件免责弹窗
- **THEN** 客户端 MUST 进入既有永久开通支付流程（MCP orders + 平台通道）

#### Scenario: 取消确认不支付

- **WHEN** 用户点击「永久开通」后在硬件免责弹窗选择取消或关闭
- **THEN** 客户端 MUST NOT 调用建单或调起支付宝 / Apple IAP

#### Scenario: 体验用尽引导开通同样确认

- **WHEN** 用户因体验已用完经引导选择永久开通
- **THEN** 客户端在进入支付前 MUST 同样展示硬件免责确认
- **AND** 取消时 MUST NOT 进入支付

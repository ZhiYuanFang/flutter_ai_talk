## ADDED Requirements

### Requirement: Apple verify business errors MUST surface server message

The client SHALL, after StoreKit reports purchased/restored and the app calls the shared Apple verify API (`POST /cash/app/api/vip/apple/verify`), surface a non-empty `ApiBusinessException.message` to the user as the payment failure copy for VIP, feature unlock, and Xiaozhi MCP permanent unlock flows.

客户端在 StoreKit 购买/恢复成功后调用服务端 Apple 验单时，若抛出 `ApiBusinessException` 且 `message` 非空，**必须**将该文案作为支付失败提示（含 VIP、功能开通、小智 MCP 永久开通）；**不得**一律替换为固定「验单失败，请稍后重试」。非业务异常（超时、未知错误等）**可以**使用通用失败文案作为 fallback。失败路径 **必须** 经 `AppDebugLog`（或等价白名单日志）记录错误，**不得** `catch (_)` 静默吞错。

#### Scenario: 小智 MCP 异号验单展示服务端文案

- **WHEN** 小智 MCP Apple 验单返回业务失败，且 `ApiBusinessException.message` 为「一个 Apple 账号仅支持开通一个胖宝账号」
- **THEN** 用户可见提示 MUST 为该文案（或以其为主体），MUST NOT 仅为「验单失败，请稍后重试」

#### Scenario: 功能开通异号验单展示服务端文案

- **WHEN** 功能开通 Apple 验单返回业务失败且 `message` 非空
- **THEN** 用户可见提示 MUST 为该 `message`

#### Scenario: 非业务异常仍可用通用文案

- **WHEN** 验单抛出非 `ApiBusinessException`（如超时）
- **THEN** 客户端 MAY 展示「验单失败，请稍后重试」或等价通用文案

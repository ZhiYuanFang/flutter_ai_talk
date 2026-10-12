## MODIFIED Requirements

### Requirement: iOS client SHALL verify Apple purchases with the server

After a successful StoreKit purchase, the iOS client MUST `POST /cash/app/api/vip/apple/verify` with `transactionId`, `productId`, and `signedTransaction` when available, and MAY include `orderNo` from the create-order step. After verify succeeds, the client MUST refresh VIP status.

When verify fails with `ApiBusinessException` and a non-empty `message`, the client MUST present that `message` as the user-visible failure copy and MUST NOT replace it with a generic「验单失败，请稍后重试」-only string.

StoreKit 成功后 **必须** 服务端验单并刷新状态；验单业务失败时 **必须** 展示服务端 `message`。

#### Scenario: 验单成功

- **WHEN** Apple verify API 返回成功
- **THEN** 客户端 MUST 再次拉取 status 且以最新 `isVip` 为准

#### Scenario: 验单业务失败展示服务端文案

- **WHEN** Apple verify API 返回业务错误且 envelope `message` 非空（经 `ApiBusinessException` 抛出）
- **THEN** 客户端 MUST 将该 `message` 展示给用户
- **AND** MUST NOT 仅展示固定「验单失败，请稍后重试」而丢弃服务端文案

## ADDED Requirements

### Requirement: Android push token SHALL be obtained via china_push only
On Android, the client SHALL initialize the `china_push` package to obtain a push registration id and manufacturer, and MUST NOT use the removed in-repo HMS/MiPush MethodChannel stack for token acquisition. 安卓推送 token **必须** 仅经 `china_push` 获取，**不得** 再使用已拆除的自研 HMS/Mi 栈。

#### Scenario: Successful init yields token path
- **WHEN** 已登录用户在已配置对应厂商密钥的 Android 设备上触发全局推送注册
- **THEN** 客户端 MUST 经 `china_push` 取得 regId，并在可映射为服务端支持 channel 时调用 `POST /app/api/push/register`

#### Scenario: Init or token failure is acceptable
- **WHEN** `china_push` 初始化失败或无法取得 regId（含未配置厂商密钥）
- **THEN** 客户端 MUST NOT 因此崩溃；MUST 跳过或失败本次注册并记录调试日志；本版该设备可不收离线推送

### Requirement: Client SHALL map china_push manufacturer to apns-hms-mipush channels only
For Android registration, the client SHALL map manufacturer to `hms` or `mipush` when applicable for the current Go senders, and MUST NOT register unknown manufacturers against unsupported channels in phase one. 一期 Android 注册 channel **必须** 仅为服务端已支持的 `hms` 或 `mipush`（iOS 仍为 `apns`）。

#### Scenario: Huawei maps to hms
- **WHEN** china_push 报告的厂商为华为系（如 HMS）且取得 regId
- **THEN** register 请求的 `channel` MUST 为 `hms`

#### Scenario: Xiaomi maps to mipush
- **WHEN** china_push 报告的厂商为小米系（如 MI）且取得 regId
- **THEN** register 请求的 `channel` MUST 为 `mipush`

#### Scenario: Unsupported manufacturer skipped
- **WHEN** 厂商无法映射到 `hms` 或 `mipush`
- **THEN** 客户端 MUST NOT 调用 register（或等价跳过），并接受该设备本版无推送

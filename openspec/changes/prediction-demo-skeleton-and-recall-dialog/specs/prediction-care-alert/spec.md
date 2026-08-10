## ADDED Requirements

### Requirement: Cold prediction states SHALL show fixed healthy care-alert copy without HTTP

While the smart prediction page is in a cold demo state (not logged in, unbound, or bound with empty prediction-range real history), the client SHALL still render the「值得留意」card with a fixed positive healthy-baby copy. The client MUST NOT call the care-alert daily fetch API (`ensureLoaded` / equivalent) for that cold state. Ignore / follow-up / detail navigation that would issue care-alert side-effect HTTP MUST NOT be available from that placeholder card.

冷态下「值得留意」**必须**仍展示固定正向健康文案；**不得**发起 care-alert 日拉取；占位卡 **不得** 触发忽略/追问等副作用 HTTP。

#### Scenario: 冷态展示固定文案

- **WHEN** 智能预测页处于冷态骨架模式
- **THEN** UI MUST 展示值得留意卡片
- **AND** 文案 MUST 为固定健康向文案（非服务端列表驱动）

#### Scenario: 冷态禁止日拉取

- **WHEN** 智能预测页处于冷态且预测页变为可见
- **THEN** 客户端 MUST NOT 调用 care-alert daily ensure/fetch

### Requirement: Care-alert daily ensure SHALL require non-empty real prediction history

When the prediction page becomes visible, the client SHALL call care-alert daily `ensureLoaded` only if the user is logged in, a usable deviceNo exists, and the prediction-range real history is ready with at least one record. Otherwise ensure MUST be skipped.

预测页可见时，客户端 **仅当** 已登录、有 deviceNo、且 range 真历史就绪且非空时 **必须** 允许 `ensureLoaded`；否则 **必须** 跳过。

#### Scenario: 有真历史才 ensure

- **WHEN** 已登录已绑定、预测 range 就绪且存在至少一条真历史，用户使预测页可见
- **THEN** 客户端 MUST 按既有副作用治理调用 ensureLoaded

#### Scenario: 空历史跳过 ensure

- **WHEN** 预测 range 就绪但真历史为空，用户使预测页可见
- **THEN** 客户端 MUST NOT 调用 ensureLoaded

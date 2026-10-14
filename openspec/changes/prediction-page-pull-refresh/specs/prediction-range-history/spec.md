## ADDED Requirements

### Requirement: User explicit range retry SHALL reset the failure circuit counter

When the user initiates an explicit retry of the seven-day prediction range load from the smart prediction page pull-to-refresh path (or an equivalent documented user retry), the client MUST reset the session consecutive-failure circuit counter for the range store to zero before starting that force reload. After the reset, the force reload MUST proceed even if the circuit was previously open. Automatic ensure paths that are not user-explicit retries MUST continue to respect an open circuit (skip non-force ensure while open) until logout, successful load (which clears the counter), or another explicit user retry.

用户从预测页下拉（或文档约定的等价显式重试）重拉 range 时，客户端 **必须** 在 force 拉取前将会话内连续失败熔断计数清零；清零后本次 force **必须** 可执行。非用户显式重试的自动 ensure **必须** 继续遵守熔断（非 force 且已开路则 skip），直至登出、成功拉取清零、或再次显式重试。

#### Scenario: 下拉前清零熔断

- **WHEN** range 连续失败已达熔断阈值（circuit open）
- **AND** 用户在预测页完成一次下拉刷新
- **THEN** 客户端 MUST 在发起该次 range force 拉取前将连续失败计数重置为 0
- **AND** MUST 仍执行该次 force 拉取（不得因「曾熔断」而跳过本次用户重试）

#### Scenario: 自动 ensure 仍尊重熔断

- **WHEN** range circuit 仍 open（用户尚未显式重试且尚未成功拉取）
- **AND** 非 force 的自动 ensure 被触发（例如进页幂等 ensure 且非 force）
- **THEN** 客户端 MUST 跳过该次网络拉取（既有熔断语义）

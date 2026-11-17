## ADDED Requirements

### Requirement: feature_def description SHALL be TEXT for long Markdown

The cash service `feature_def.description` column MUST be typed as `TEXT`（not `VARCHAR(512)`）for new schema creation. Existing deployments MUST receive an idempotent EnsureSchema migration that `MODIFY`s `description` to `TEXT NOT NULL`（preserving existing values）. Admin Hub update APIs MUST continue to accept a string `description` and persist it without a 512-character hard cap at the column layer. App catalog responses MUST continue to return `description` as a string so clients MAY render Markdown（including multi-line lists）for features such as `predict_capability_pro`.

`feature_def.description` MUST 为 TEXT；EnsureSchema MUST 幂等扩列；Hub/App MUST 透传长字符串，不得再以 512 列宽截断存储。

#### Scenario: 新库建表为 TEXT

- **WHEN** 全新环境执行 cash EnsureSchema 建表
- **THEN** `feature_def.description` MUST 为 TEXT（或等价无限长文本类型），MUST NOT 为 VARCHAR(512)

#### Scenario: 已有库幂等升级

- **WHEN** 已有 `VARCHAR(512)` 的库再次 EnsureSchema
- **THEN** 服务 MUST 将 `description` 升级为 TEXT 且 MUST NOT 因重复执行失败而阻断启动

#### Scenario: Hub 可存长 MD

- **WHEN** 管理员将超过 512 字符的 Markdown `description` 写入 `predict_capability_pro`
- **THEN** 存储 MUST 成功保留全文
- **AND** App catalog 该字段 MUST 返回同等全文供客户端渲染

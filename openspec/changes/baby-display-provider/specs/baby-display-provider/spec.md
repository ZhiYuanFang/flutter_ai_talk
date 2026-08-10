## ADDED Requirements

### Requirement: 客户端 SHALL 提供宝宝身份展示快照 Provider

The client MUST expose a Riverpod provider (e.g. `babyDisplayProvider`) that watches the settings baby load path and yields an immutable display snapshot whose nickname, age text, identity line, and avatar `babyId`/`sex` are resolved exclusively through the L1 baby display atoms (or equivalent). While the async baby profile is loading or has no data, the snapshot MUST use the same empty-state fallbacks as L1 with a null profile. The client MAY also expose `currentBabyProvider` (or equivalent) returning `BabyProfile?` from `AsyncValue.asData`.

客户端 **必须** 提供 Riverpod 展示快照 Provider（如 `babyDisplayProvider`）：watch 设置宝宝加载路径，产出不可变快照，其昵称、月龄、身份行与头像 `babyId`/`sex` **必须** 仅经 L1 宝宝展示原子（或等价）解析。异步资料 loading 或无 data 时，快照 **必须** 与 L1 在 `null` profile 下的空态一致。客户端 MAY 另提供 `currentBabyProvider`（或等价）返回 `AsyncValue.asData` 的 `BabyProfile?`。

#### Scenario: loading 时快照为空态

- **WHEN** `settingsBabyProvider`（或等价）尚无 `asData`
- **AND** 调用方 watch 展示快照 Provider
- **THEN** 快照昵称 MUST 为「宝宝」
- **AND** 月龄 MUST 为「不满1个月啦」
- **AND** `babyId` MUST 为空且 `sex` MUST 为 `unknown`

#### Scenario: 有资料时快照与 L1 一致

- **WHEN** 宝宝资料已加载且昵称非空、生日可用
- **THEN** 快照昵称/月龄/头像入参 MUST 分别与对应该资料调用 L1 原子的结果一致

### Requirement: 喂养与预测身份展示 MUST 经展示快照 Provider

The feeding immersive header identity wiring, the smart prediction baby identity header, and the feeding empty-history name interpolation MUST obtain identity display fields by watching the baby display snapshot provider (or reading equivalent snapshot fields), and MUST NOT repeat `watch(settingsBabyProvider).asData?.value` plus scattered L1 calls at those call sites. Screens that need explicit loading/error UI via `AsyncValue.when` (e.g. settings baby card) MUST NOT be required to migrate.

喂养沉浸头身份接线、智能预测宝宝身份顶栏、以及喂养空历史姓名插值 **必须** 通过 watch 宝宝展示快照 Provider（或读取等价快照字段）取得身份展示字段，**不得** 在这些调用点重复 `watch(settingsBabyProvider).asData?.value` 并散落调用 L1。需要 `AsyncValue.when` 显式加载/错误 UI 的页面（如设置宝宝卡）**不得** 被要求迁移。

#### Scenario: 喂养顶栏经快照 Provider

- **WHEN** 喂养页渲染沉浸头身份条
- **THEN** 昵称、月龄与头像入参 MUST 来自展示快照 Provider
- **AND** 该调用点 MUST NOT 再手写 `settingsBabyProvider` 的 `asData?.value` 仅用于该身份条

#### Scenario: 预测顶栏经快照 Provider

- **WHEN** 智能预测页渲染宝宝身份顶栏
- **THEN** 昵称、月龄与头像入参 MUST 来自展示快照 Provider

#### Scenario: 空历史经快照昵称

- **WHEN** 喂养空历史展示「还没有为 {name} 记录」类文案
- **THEN** `{name}` MUST 取自展示快照的昵称字段（或等价 Provider 派生）

### Requirement: 身份快照 MUST NOT 订阅预测秒级时钟

The default baby display snapshot provider used for identity chrome MUST NOT watch `predictionClockProvider` solely to recompute age text. Age text MAY use wall-clock time at resolve. Prediction countdown UI MAY continue to watch `predictionClockProvider` independently.

用于身份铬层的默认展示快照 Provider **不得** 仅为重算月龄而 watch `predictionClockProvider`。月龄 MAY 在 resolve 时使用墙钟。预测倒计时 UI MAY 继续独立 watch `predictionClockProvider`。

#### Scenario: 喂养头不因预测 clock 每秒重建身份月龄

- **WHEN** `predictionClockProvider` 发出新的秒级时刻
- **THEN** 仅因该 clock 更新 **不得** 强制默认身份快照 Provider 仅为此重算月龄文案

## MODIFIED Requirements

### Requirement: 喂养与预测身份展示 MUST 使用展示原子

The feeding immersive header identity wiring and the smart prediction page baby identity header MUST obtain nickname, age text, and avatar id/sex from the baby display snapshot provider (e.g. `babyDisplayProvider`), whose fields MUST themselves be resolved via the L1 baby display atoms. Those call sites MUST NOT repeat `watch(settingsBabyProvider).asData?.value` plus scattered L1 calls. The feeding empty-history copy that interpolates the baby name MUST use the snapshot nickname (or L1 via that snapshot) rather than a raw `?? '宝宝'`.

喂养沉浸头身份接线与智能预测页宝宝身份顶栏 **必须** 从宝宝展示快照 Provider（如 `babyDisplayProvider`）取得昵称、月龄与头像 id/sex，且该快照字段 **必须** 经 L1 展示原子解析。上述调用点 **不得** 重复 `watch(settingsBabyProvider).asData?.value` 并散落调用 L1。喂养空历史插值宝宝名 **必须** 使用快照昵称（或经该快照的 L1），**不得** 使用裸 `?? '宝宝'`。

#### Scenario: 喂养顶栏经快照与原子

- **WHEN** 喂养页渲染沉浸头身份条
- **THEN** 昵称与月龄（或合成行）及头像入参 MUST 来自展示快照 Provider
- **AND** 快照内对应字段 MUST 与 L1 空态规则一致

#### Scenario: 预测顶栏经快照与原子

- **WHEN** 智能预测页渲染宝宝身份顶栏
- **THEN** 昵称、月龄文案与头像入参 MUST 来自展示快照 Provider

#### Scenario: 空历史昵称经快照

- **WHEN** 喂养页在无历史时展示「还没有为 {name} 记录」类文案且资料昵称为空白
- **THEN** `{name}` MUST 为「宝宝」

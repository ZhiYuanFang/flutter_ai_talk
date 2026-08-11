## ADDED Requirements

### Requirement: 身份展示原子 MUST 将仓库占位昵称视为无效

For in-app L1 baby identity nickname resolution, the repository unbound placeholder nickname「未绑定宝宝ID」（and equivalent whitespace-only / empty cases）MUST NOT be shown as the display nickname; it MUST resolve to the same empty-nickname fallback「宝宝」. This rule MUST NOT be the source of guest/unbound chrome copy（「未登录」/「未绑定宝宝」），which SHALL be applied by the auth-aware display snapshot layer.

应用内 L1 身份昵称解析时，仓库未绑定占位昵称「未绑定宝宝ID」（以及空/仅空白）**不得** 作为展示昵称原样输出，**必须** 回退为「宝宝」。游客/未绑定顶栏文案（「未登录」/「未绑定宝宝」）**不得** 依赖本规则产生，而 SHALL 由会话感知的展示快照层施加。

#### Scenario: 占位昵称回退宝宝

- **WHEN** 传入 profile 的 `nickname` 为「未绑定宝宝ID」
- **AND** 调用 L1 `displayBabyNickname`（或等价）
- **THEN** 返回值 MUST 为「宝宝」

### Requirement: 身份合成行在无月龄时 MUST NOT 强拼分隔符

When composing an in-app identity line from nickname and age text, if age text is empty (age hidden), the client MUST return only the nickname and MUST NOT insert「 · 」or trailing/leading separators.

当由昵称与月龄合成应用内身份行且月龄为空（隐藏月龄）时，客户端 **必须** 仅返回昵称，**不得** 插入「 · 」或首尾多余分隔符。

#### Scenario: 空月龄仅昵称

- **WHEN** 昵称为「未登录」且月龄文案为空
- **THEN** 合成身份行 MUST 为「未登录」
- **AND** MUST NOT 包含「 · 」

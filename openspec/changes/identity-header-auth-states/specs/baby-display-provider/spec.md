## ADDED Requirements

### Requirement: 身份展示快照 MUST 按登录与绑定态覆盖顶栏文案

When producing the in-app baby identity display snapshot used by feeding and prediction headers, the client MUST watch session and usable deviceNo (bound = logged in and non-empty deviceNo). While the user is not logged in, the snapshot nickname MUST be「未登录」, age text MUST be empty, and the composed identity line MUST be only that nickname (MUST NOT append「 · 」or age). While the user is logged in but unbound, the snapshot nickname MUST be「未绑定宝宝」, age text MUST be empty, and the identity line MUST be only that nickname. When logged in and bound, nickname/age/identity line MUST continue to resolve through L1 baby display atoms from the loaded profile (or L1 null-profile fallbacks while loading). The snapshot MUST expose a clear signal for whether age should be shown (e.g. `showAge` or empty `ageText` convention) so headers can hide the age row/segment.

用于喂养/预测顶栏的宝宝身份展示快照 **必须** watch 会话与可用 deviceNo（已绑定 = 已登录且 deviceNo 非空）。未登录时昵称 **必须** 为「未登录」、月龄 **必须** 为空、合成行 **必须** 仅为该昵称（**不得** 拼接「 · 」或月龄）。已登录未绑定时昵称 **必须** 为「未绑定宝宝」、月龄为空、合成行仅为该昵称。已登录已绑定时昵称/月龄/合成行 **必须** 继续经 L1 由已加载 profile 解析（loading 时可用 L1 空态）。快照 **必须** 提供是否展示月龄的明确信号（如 `showAge` 或空 `ageText` 约定），供顶栏隐藏月龄段/行。

#### Scenario: 未登录快照

- **WHEN** 用户未登录且调用方 watch 展示快照 Provider
- **THEN** 昵称 MUST 为「未登录」
- **AND** 月龄文案 MUST 为空
- **AND** 合成身份行 MUST 为「未登录」（无「 · 」）

#### Scenario: 已登录未绑定快照

- **WHEN** 用户已登录且无可用 deviceNo
- **AND** 调用方 watch 展示快照 Provider
- **THEN** 昵称 MUST 为「未绑定宝宝」
- **AND** 月龄文案 MUST 为空
- **AND** 合成身份行 MUST 为「未绑定宝宝」

#### Scenario: 已绑定仍走 L1

- **WHEN** 用户已登录且存在可用 deviceNo，宝宝资料已加载且昵称非空、生日可用
- **THEN** 快照昵称/月龄 MUST 分别与对应该资料调用 L1 原子的结果一致

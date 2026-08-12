## ADDED Requirements

### Requirement: 已绑定但画像占位时 MUST NOT 展示虚假月龄合成行

When `babyDisplayProvider` (or equivalent identity snapshot) observes a logged-in user with non-empty usable `deviceNo`, but the loaded baby profile is still the unbound placeholder (`id` empty and/or nickname「未绑定宝宝ID」) or otherwise not yet a usable bound profile, the client MUST NOT present the normal bound L1 composition that shows default nickname「宝宝」together with age text「不满1个月啦」as if the baby were bound with a real birth date. The snapshot MUST hide age (`showAge` false or empty age text) until a usable bound profile arrives. Settings MUST NOT show the primary「尚未绑定宝宝ID / 去绑定」CTA solely because profile id is empty while usable `deviceNo` is already present; it MUST treat that as loading/syncing (or error/retry) instead of unbound. 当身份快照观察到已登录且可用 `deviceNo` 非空，但画像仍为未绑定占位（空 id 与/或昵称「未绑定宝宝ID」）或尚非可用绑定画像时，客户端 **不得** 以已绑定 L1 合成行同时展示默认「宝宝」与「不满1个月啦」；在可用绑定画像到达前 **必须** 隐藏月龄。设置中心 **不得** 在可用 `deviceNo` 已存在时仅因画像 id 为空就展示主路径「尚未绑定 / 去绑定」，**必须** 视为同步中或错误重试。

#### Scenario: deviceNo 已有、画像仍占位时顶栏无虚假月龄

- **WHEN** 用户已登录且 `deviceNo` 非空
- **AND** 当前 `settingsBaby` 画像仍为空 id 或昵称为「未绑定宝宝ID」
- **THEN** 身份快照 MUST NOT 展示「不满1个月啦」（或其它基于占位生日的月龄）
- **AND** `showAge` MUST 为 false 或月龄文案为空

#### Scenario: deviceNo 已有时设置不误导去绑定

- **WHEN** 用户已登录且 `deviceNo` 非空
- **AND** 画像仍在加载或仍为占位空 id
- **THEN** 设置中心 MUST NOT 展示与「无 deviceNo」相同的「尚未绑定宝宝ID，点击前往绑定」主 CTA
- **AND** MUST 展示加载/同步中或失败重试态之一

#### Scenario: 有效画像到达后恢复 L1

- **WHEN** 用户已登录、`deviceNo` 非空且画像已加载为有效非空 id
- **THEN** 身份快照 MUST 按既有已绑定路径经 L1 解析昵称与月龄
- **AND** 设置中心 MUST 展示只读/可编辑宝宝资料卡（非绑定 CTA）

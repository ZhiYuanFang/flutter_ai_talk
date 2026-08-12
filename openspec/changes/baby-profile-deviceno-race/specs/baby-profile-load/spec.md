## ADDED Requirements

### Requirement: 宝宝画像 Provider MUST 随 deviceNo 变化重新加载

When the client exposes baby profile for settings and identity display via `settingsBabyProvider` (or equivalent), it MUST depend on the current usable `deviceNo` from `deviceNoNotifierProvider` (or equivalent). When the normalized deviceNo changes (empty↔non-empty or A→B), the provider MUST reload the baby profile and MUST NOT keep serving a previously cached unbound placeholder (`id` empty / nickname「未绑定宝宝ID」) as the terminal state for a now-bound session. After logged-in gateway bootstrap successfully loads a baby profile, the client MUST refresh the same display provider so it matches the bootstrap result (e.g. invalidate), and MUST NOT update only theme/sex side channels while leaving the profile provider stale. 宝宝画像展示 Provider **必须**依赖当前可用 `deviceNo`；规范化 deviceNo 变化时 **必须**重载画像，**不得**在已绑定会话中继续把先前缓存的未绑定占位当作终态；已登录 bootstrap 成功 `loadBaby` 后 **必须**刷新同一展示 Provider，与 bootstrap 结果一致，**不得**只写性别/主题旁路而留下陈旧画像。

#### Scenario: deviceNo 从空变为非空后重载

- **WHEN** 用户已登录，本地 `deviceNo` 从空变为非空
- **THEN** `settingsBabyProvider`（或等价）MUST 重新执行画像加载
- **AND** 成功后返回的 `BabyProfile.id` MUST 为该 deviceNo（或服务端回写的等价 id），MUST NOT 保持空 id 占位

#### Scenario: bootstrap loadBaby 后展示 Provider 一致

- **WHEN** `GatewayBootstrapGate`（或等价）已登录单飞路径成功完成 `loadBaby`
- **THEN** 展示用 `settingsBabyProvider`（或等价）MUST 在此后可读到与本次加载一致的有效画像（经 invalidate/覆写）
- **AND** MUST NOT 仅更新 `babySexProvider` 而让设置中心仍读到空 id 占位

#### Scenario: 真未绑定仍可进绑定

- **WHEN** 用户已登录且规范化 `deviceNo` 仍为空
- **THEN** 设置中心 MUST 仍可展示绑定宝宝入口（与现有未绑定路径一致）

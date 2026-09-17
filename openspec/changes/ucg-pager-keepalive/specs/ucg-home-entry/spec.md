## ADDED Requirements

### Requirement: UCG PageView slot SHALL keep alive after first mount

After the user first navigates to the UCG page on the `/home` PageView and `UcgShell` has been mounted, the client MUST keep the UCG page State alive across subsequent horizontal page switches away from and back to UCG (`AutomaticKeepAliveClientMixin` or equivalent), matching the keep-alive behavior already required for the feeding page. The client MUST still defer the first build/mount of `UcgShell` until the first navigation to the UCG index (lazy mount). Leaving UCG and returning MUST NOT dispose and remount `UcgShell` solely due to PageView index change, and MUST NOT re-run the square「推荐」initial full refresh (`_load(refresh: true)` / equivalent) solely because of that remount.

用户首次进入 `/home` PageView 的 UCG 页并挂载 `UcgShell` 之后，客户端 **必须** 在之后离开再返回 UCG 时保活 UCG 页 State（`AutomaticKeepAliveClientMixin` 或等价），与喂养页保活一致。首次进入前仍 **必须** 懒挂载。仅因 PageView 切页离开再返回 **不得** dispose/remount `UcgShell`，也 **不得** 仅因此再次触发广场「推荐」整表首刷。

#### Scenario: 预测与 UCG 往返保留推荐列表

- **WHEN** 用户已进入 UCG 且「推荐」Feed 已加载出非空列表
- **AND** 用户横滑到智能预测页再横滑回 UCG
- **THEN** 客户端 MUST 保留广场推荐列表内容（不得呈现整表清空后的完整首刷加载态作为唯一路径）
- **AND** MUST NOT 仅因本次切页再次调用推荐 Feed 的 refresh 首页请求

#### Scenario: 冷启仍懒挂载 UCG

- **WHEN** 用户冷启动停留在预测页（或喂养页）且从未进入 UCG
- **THEN** 客户端 MUST NOT 构建 `UcgShell`
- **AND** MUST NOT 因 `/home` 挂载而发起广场推荐首刷或 UCG 定位授权

#### Scenario: 首次进入 UCG 仍允许首刷

- **WHEN** 用户会话内首次横滑进入 UCG 且资格合格
- **THEN** 客户端 MAY 挂载 `UcgShell` 并执行广场「推荐」初始 `_load(refresh: true)`（或等价）

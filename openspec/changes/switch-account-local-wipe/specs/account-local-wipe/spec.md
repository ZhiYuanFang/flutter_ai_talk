## ADDED Requirements

### Requirement: Switch-account and deregistration SHALL wipe local baby and feeding caches

When the user confirms switch-account or successfully completes account deregistration, the client MUST wipe local state that could leak the previous account’s baby identity or feeding history into the next session. The wipe MUST include at least: session tokens, sign-in channel, cached `deviceNo`, feeding-history disk cache and in-process history memory (including any process-wide history memory cache and the home-history notifier state), local baby profile prefs for the outgoing device, and local baby avatar copy for that baby when identifiable. The client MUST invalidate Riverpod providers that surface baby profile/display so UI does not keep stale async data. The wipe MUST NOT clear the credential history store used for login suggestions. Navigation back to login MUST remain possible after the account sheet is dismissed (host/container-safe).

用户确认切换账号，或注销成功后，客户端 **必须** 擦除可能把上一账号宝宝身份或喂养历史带入下一会话的本地状态，至少包括：会话 token、登录渠道、缓存 `deviceNo`、喂养历史磁盘与进程内历史内存（含进程级历史 memory cache 与 homeHistory 状态）、该设备对应的宝宝 prefs 画像、可识别时的宝宝头像本地副本；**必须** invalidate 宝宝画像/展示相关 Provider；**不得**清除登录凭据历史 store；Sheet 关闭后仍 **必须** 能安全跳转登录。

#### Scenario: 切换账号后无旧历史内存

- **WHEN** 用户确认切换账号并完成本地擦除
- **THEN** 喂养历史磁盘缓存 MUST 为空（或等价已清除），且进程内历史 memory / homeHistory 展示态 MUST NOT 仍持有上一账号的记录列表

#### Scenario: 切换账号后无旧宝宝画像缓存

- **WHEN** 用户确认切换账号并完成本地擦除，且擦除前存在可用的 `deviceNo`
- **THEN** 该 `deviceNo` 对应的本地宝宝 prefs 画像 MUST 被移除；宝宝展示 Provider MUST 不再提供上一账号的有效画像（未绑定空态除外）

#### Scenario: 不得清凭据历史

- **WHEN** 用户执行切换账号本地擦除
- **THEN** 客户端 MUST NOT 清除凭据历史 store（账号建议列表）

#### Scenario: 注销成功共用擦除

- **WHEN** 用户注销账户成功
- **THEN** 客户端 MUST 执行与切换账号同等范围的本地宝宝/喂养擦除（凭据条目移除按既有注销规格另行处理），并导航至登录

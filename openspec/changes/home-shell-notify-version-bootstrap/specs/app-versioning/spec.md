## ADDED Requirements

### Requirement: 主壳挂载后自动版本检查 MUST 含游客且排在 notify 之后

After `UcgHomeShell` mounts on `/home`, the client SHALL run the automatic version check (and show `maybeShowVersionPrompt` when an update is indicated) for **both guest and signed-in users**. This automatic check MUST run only as the second step of the home-shell dialog bootstrap (after notify handling completes, including awaiting any notify dialog dismiss). The client MUST NOT run this automatic check on app resume or when the user signs in while the shell is already mounted. The settings-screen manual「检查更新」entry MUST remain available to guests and signed-in users unchanged. 主壳挂载后自动版本检查 **必须** 对游客与已登录用户均执行；**必须** 作为启动编排第二步（notify 完成之后）；resume 与登录中途 **不得** 自动弹；设置手动检查 **必须** 保留。

#### Scenario: 游客冷启发现新版本

- **WHEN** 未登录用户进入 `/home`，notify 未展示弹窗（或已关闭），且 version/check 表明需要更新
- **THEN** 客户端 MUST 展示与已登录用户相同的更新提示 UI

#### Scenario: notify 关闭前不弹 version

- **WHEN** notify 可关闭公告弹窗仍在展示中
- **THEN** 客户端 MUST NOT 同时展示版本更新弹窗

#### Scenario: 登录中途不自动 version

- **WHEN** 主壳已挂载期间用户登录成功
- **THEN** 客户端 MUST NOT 因此自动发起版本弹窗（用户仍可在设置中手动检查）

#### Scenario: resume 不自动 version

- **WHEN** 应用 resume 且主壳仍挂载
- **THEN** 客户端 MUST NOT 仅因 resume 自动展示版本更新弹窗

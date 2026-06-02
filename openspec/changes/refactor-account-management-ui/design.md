## Context

设置页 `SettingsScreen` 当前将「切换账号」「注销账户」作为独立 glass tile，「账号管理」则打开 Material `showModalBottomSheet`，内含改密（AlertDialog）、手动输入 jsCode 绑微信、绑定设备号、微信补齐密码及联调登录校验。宝宝绑定已在设置页顶部独立展示（`/settings/bind-baby`）。

后端新增 `GET /device/app/api/user/profile`（Bearer），返回 `account`（纯微信用户恒为空）、`isWxBound`。项目已有玻璃 overlay 体系（`app_glass_overlay.dart`、`HistoryEditGlassPanel`）及微信 OAuth（`WeChatAuthClient.obtainWxCode()`）。

## Goals / Non-Goals

**Goals:**

- 账号生命周期操作（改密、绑微信、切换、注销）集中在一个玻璃 BottomSheet。
- 以 `user/profile` 驱动条件 UI：`account` 非空 → 改密；`isWxBound` → 微信状态。
- 改密独立全屏页（push `/settings/change-password`），成功后仅清会话并带 account 重登。
- 绑微信走 OAuth，禁止手动输入 code；已绑定只读展示。
- 移除所有面向用户的联调/后端概念入口。

**Non-Goals:**

- 不改变设置页顶部「绑定宝宝」入口与 `BabyBindScreen` 逻辑。
- 不删除仓储层 `createUsernameForWx`、`bindUsernameDevice`、`loginUsernameBusiness` 方法（仅 UI 不暴露）。
- 不改造登录/注册页整体视觉（除 query 预填 account）。
- 不支持微信改绑或解绑。

## Decisions

1. **Profile 数据层**  
   在 `AuthRepository` 新增 `fetchUserProfile()`，调用 `GET /device/app/api/user/profile`，解析为 `UserAccountProfile { account, isWxBound }`。  
   - 备选：独立 `UserProfileRepository` — 未采用，账号域操作已集中在 auth 层，减少 provider 组合。

2. **状态暴露**  
   `userProfileProvider`（`FutureProvider`）在已登录态拉取；打开账号管理 Sheet 与绑定微信成功后 `invalidate` 刷新。  
   - 备选：写入 SessionController — 未采用，profile 与会话 token 生命周期不同，按需拉取更合适。

3. **改密入口条件**  
   `profile.account` 非空即展示改密（有 account 即有密码；纯微信用户 account 恒空）。不依赖 `SignInChannel` 判断。  
   - 备选：SignInChannel.username — 未采用，以后端 profile 为单一真相源。

4. **账号管理载体**  
   `showGlassAdaptiveBottomSheet` + 玻璃列表项（`historyEditGlassTextColor` / `historyEditGlassLabelColor`）。  
   - 备选：独立全屏账号管理页 — 未采用，操作项少，Sheet 更轻。

5. **改密页与重登**  
   `context.push('/settings/change-password')`；成功后 `sessionProvider.signOut()` **仅清 token**，**不**清 `deviceNo`、历史缓存、宝宝 prefs（与「切换账号」全量清理区分）；`context.go('/login?account=xxx')`；LoginScreen 读取 query 预填账号框。  
   - 备选：SharedPreferences 临时键 — 未采用，GoRouter query 更直接，与注册回流模式一致。

6. **绑定微信**  
   Sheet 内点击 → `weChatAuthClient.obtainWxCode()` → `bindUsernameWx(jsCode:)` → `showGlassDialog` 成功提示 → invalidate profile。用户取消抛 `WeChatAuthCanceledException` 时轻 toast，不展示技术错误。  
   - 备选：手动输入 jsCode — 已废弃，不符合产品要求。

7. **设置页结构调整**  
   移除顶层「切换账号」「注销账户」tile；subtitle 更新为产品向文案（如「改密 / 绑定微信 / 切换与注销」）。

## Risks / Trade-offs

- **[Risk] profile 接口失败时 Sheet 无法渲染条件项** → Sheet 打开时展示 loading；失败 toast 并允许关闭，不 crash。
- **[Risk] 改密重登与切换账号清理范围混淆** → 抽取 `_signOutForPasswordChange()`（仅 session）与现有切换账号全量清理分离，代码 review 重点检查。
- **[Risk] Web 端微信绑定的 OAuth 回流** → 复用登录同源 `WeChatAuthClient`；Web 需已配置 redirect，与登录一致。
- **[Trade-off] profile 非实时** → 仅打开 Sheet / 绑微信成功后刷新；可接受，账号绑定状态变更频率低。

## Migration Plan

1. 落 OpenSpec 制品并通过校验。
2. 实现 profile 接口与 provider。
3. 重构账号管理 Sheet + 改密页 + 登录预填。
4. 移除旧 UI 入口与联调项。
5. 手工回归：纯微信用户 Sheet、账号用户改密重登、绑微信 OAuth、切换账号、注销。

回滚： revert UI 变更即可，profile 接口为 additive，不影响旧客户端必需路径。

## Open Questions

（无 — explore 阶段已全部确认。）

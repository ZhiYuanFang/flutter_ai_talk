## ADDED Requirements

### Requirement: 账号管理必须使用玻璃 BottomSheet 集中展示生命周期操作
The account management entry MUST present switch-account, deregister, conditional change-password, and conditional WeChat bind actions inside a glassmorphism bottom sheet.

设置页在已登录态必须提供单一「账号管理」入口；点击后必须通过 `showGlassAdaptiveBottomSheet`（或等价玻璃 overlay 入口）展示操作列表。切换账号与注销账户必须从设置页顶层移入该 Sheet。Sheet 内文字 MUST 使用 `historyEditGlassTextColor` / `historyEditGlassLabelColor`（或等价 token）。

#### Scenario: 打开账号管理 Sheet
- **WHEN** 已登录用户在设置页点击「账号管理」
- **THEN** 客户端必须展示玻璃 BottomSheet
- **AND** MUST NOT 使用实心 Material bottom sheet 作为可见面板

#### Scenario: Sheet 展示切换账号与注销
- **WHEN** 账号管理 Sheet 打开
- **THEN** 必须包含「切换账号」与「注销账户」操作项
- **AND** 设置页顶层 MUST NOT 再独立展示这两项

#### Scenario: 打开 Sheet 时刷新 profile
- **WHEN** 账号管理 Sheet 即将展示
- **THEN** 客户端必须拉取或刷新 `user/profile`
- **AND** 根据 `account` 与 `isWxBound` 条件渲染改密与微信项

### Requirement: 修改密码必须使用独立页面并在成功后强制重新登录
The change-password flow MUST use a dedicated screen showing read-only `account`, and MUST force re-login with prefilled account after success.

当 `profile.account` 非空时，账号管理 Sheet 必须展示「修改密码」；点击后必须 `push` 至独立改密页。改密页必须只读展示当前 `account`（不可编辑），并提供旧密码、新密码输入。改密 API 成功后必须清除会话 token、保留本地宝宝与历史缓存，并导航至 `/login?account={account}`；登录页必须预填该账号。

#### Scenario: 有 account 时展示改密入口
- **WHEN** `profile.account` 非空
- **THEN** 账号管理 Sheet 必须展示「修改密码」
- **WHEN** `profile.account` 为空
- **THEN** MUST NOT 展示「修改密码」

#### Scenario: 改密页展示当前账号
- **WHEN** 用户进入改密页
- **THEN** 必须只读展示 `profile.account`
- **AND** 用户不得在该页修改账号字段

#### Scenario: 改密成功后强制重登
- **WHEN** `POST /device/app/api/user/username/change_password` 成功
- **THEN** 客户端必须清除 access/refresh token（signOut）
- **AND** MUST NOT 清除本地 `deviceNo`、宝宝 profile prefs、历史缓存（与「切换账号」全量清理区分）
- **AND** 必须导航至登录页并预填 `account` query 参数
- **AND** 必须提示用户密码已修改、请重新登录

### Requirement: 绑定微信必须由 OAuth 获取 code 且已绑定不可改绑
WeChat binding in account management MUST use platform OAuth to obtain `jsCode`; bound users MUST see a read-only state without rebind.

当 `profile.isWxBound == false` 时，Sheet 必须展示可点击的「绑定微信」；点击后必须调起微信 OAuth（`WeChatAuthClient.obtainWxCode()` 或 Web 等价流程）取得 `code`，并调用 `POST /device/app/api/user/username/bindwx`（Bearer）。成功后必须展示玻璃确认对话框提示绑定成功，并刷新 profile。当 `isWxBound == true` 时必须展示「已绑定微信」且不可点击、不可改绑。

#### Scenario: 未绑定微信时发起 OAuth 绑定
- **WHEN** `isWxBound == false` 且用户点击「绑定微信」
- **THEN** 客户端必须调起微信授权获取 `code`
- **AND** 必须调用 `bindUsernameWx` 提交 `jsCode` 与 `platform`
- **AND** MUST NOT 要求用户手动输入 `jsCode`
- **AND** 成功后必须弹框提示「绑定微信账号成功」（或等价产品文案）

#### Scenario: 用户取消微信授权
- **WHEN** 用户在 OAuth 流程中取消
- **THEN** 客户端必须轻量提示（如 Toast）已取消
- **AND** MUST NOT 展示技术堆栈或联调向错误

#### Scenario: 已绑定微信只读展示
- **WHEN** `isWxBound == true`
- **THEN** Sheet 必须展示「已绑定微信」
- **AND** 该项 MUST NOT 可点击或提供改绑入口

## MODIFIED Requirements

### Requirement: 客户端必须支持用户名账号注册与业务登录校验接口
The client SHALL support username registration; the business login endpoint MAY remain in the repository but MUST NOT be exposed in production UI.

客户端必须支持 `POST /device/app/api/user/username/register` 及与主登录一致的账号密码规范化；`POST /device/app/api/user/username/login` 可保留于仓储层供联调，但生产 UI 不得暴露「业务登录校验」入口。

#### Scenario: 注册新账号成功
- **WHEN** 用户提交合法 `account` 与 `password`
- **THEN** 客户端必须调用 `POST /device/app/api/user/username/register`
- **AND** 成功后必须给出成功反馈并允许继续登录流程

### Requirement: Bearer 账号管理接口必须在已登录态可用
The client MUST expose authenticated change-password and WeChat-bind user flows; bind-device and create-username MUST NOT appear in account-management UI.

客户端在 Bearer 会话下必须支持用户可见的改密（`/user/username/change_password`）与绑微信（`/user/username/bindwx`）；不得在账号管理 UI 暴露绑定设备号或补齐用户名密码。

#### Scenario: 已登录用户修改密码
- **WHEN** 用户在改密页提交旧密码与新密码
- **THEN** 客户端必须调用 `POST /device/app/api/user/username/change_password`（Bearer）
- **AND** 成功后必须清除会话并导航至登录页预填 `account`

#### Scenario: 已登录用户绑定微信
- **WHEN** 用户通过 OAuth 提交 `jsCode` 与 `platform`
- **THEN** 客户端必须调用 `POST /device/app/api/user/username/bindwx`（Bearer）
- **AND** 成功后不得改变当前 token 持久化状态（直至用户主动登出或改密重登）

## REMOVED Requirements

### Requirement: 微信已登录用户创建用户名密码
**Reason**: 产品决策：微信用户仅保留微信登录渠道，不再引导补齐用户名密码。

**Migration**: 移除账号管理中「微信账号补齐用户名密码」入口；仓储 `create_username` 可保留但不暴露 UI。

#### Scenario: 已登录用户绑定设备号
**Reason**: 用户可见的「绑定设备号」已从账号管理移除；宝宝绑定改由设置页「绑定宝宝」承担。

**Migration**: 使用 `/settings/bind-baby` 与 `POST /device/app/api/user/bindwx`（用户文案为宝宝ID）；`bind_username_device` 不出现在账号管理 UI。

#### Scenario: 调用业务登录接口成功
**Reason**: 联调向业务登录校验不得向最终用户暴露。

**Migration**: 接口可保留于 `AuthRepository` 供开发文档；设置/账号管理 UI 不得提供入口。

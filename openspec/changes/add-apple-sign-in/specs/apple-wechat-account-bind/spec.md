## ADDED Requirements

### Requirement: 已登录用户 SHALL 可选绑定第二登录方式到当前账号
The client SHALL allow logged-in users to optionally bind a second auth provider (Apple or WeChat) to the current `wx` row via Bearer bind APIs.
已登录用户必须能够（可选）将第二登录方式绑定到**当前**会话对应账号：Apple-only 用户可绑定微信；WeChat-only 用户（iOS）可绑定 Apple。绑定须调用 Bearer 接口 `POST /device/app/api/user/wx/bindwx` 或 `POST /device/app/api/user/apple/bind`，且**不得**尝试合并两条已独立存在的完整账号。

#### Scenario: Apple-only 用户绑定微信成功
- **WHEN** 用户以 Apple 登录且 profile 显示未绑定微信（`isWxBound=false`），在账号管理点击「绑定微信」并完成微信授权
- **THEN** 客户端必须调用 `bindWx`（`wx/bindwx` + `jsCode`）
- **AND** 绑定成功后必须刷新 profile，展示微信已绑定状态
- **AND** 当前 `wxId` 与会话 token 必须保持不变

#### Scenario: WeChat-only 用户绑定 Apple 成功（iOS）
- **WHEN** 用户以微信登录且 profile 显示未绑定 Apple（`isAppleBound=false`），在账号管理点击「绑定 Apple」并完成 Apple 授权
- **THEN** 客户端必须取得 `identityToken` 并调用 `bindApple`（`apple/bind`）
- **AND** 绑定成功后必须刷新 profile，展示 Apple 已绑定状态

#### Scenario: 双绑完成后只读展示
- **WHEN** profile 显示 `isAppleBound=true` 且 `isWxBound=true`（或 `authProviders` 同时含 `apple` 与 `wechat`）
- **THEN** 账号管理必须展示只读绑定状态
- **AND** 不得再展示可触发的重复绑定入口（除非产品后续允许解绑，本变更不要求）

#### Scenario: 用户不绑定第二方式
- **WHEN** 用户仅使用 Apple 或仅使用微信且从未打开绑定流程
- **THEN** 客户端必须允许正常使用
- **AND** 账号管理不得强制弹出绑定

### Requirement: 绑定冲突须展示明确不可合并提示
When bind APIs return identifier-taken or merge-conflict errors, the client SHALL show a clear message that two separately created accounts cannot be merged.
当用户曾分别以 Apple、微信各独立登录并产生两个 `wxId`，事后尝试绑定时，后端将返回 `ErrAppleSubTakenByOther`、`ErrUnionIDTakenByOther` 或 `ErrAccountMergeConflict`；客户端必须映射为可理解提示，明确说明**无法合并两个已独立创建的账号**。

#### Scenario: Apple 标识已被其他账号占用
- **WHEN** `bindApple` 返回 `ErrAppleSubTakenByOther` 或 `ErrAccountMergeConflict`
- **THEN** 客户端必须 Toast 或对话框说明该 Apple 账号已关联其他胖宝账号、无法合并
- **AND** 不得覆盖当前会话或切换账号

#### Scenario: 微信 unionid 已被其他账号占用
- **WHEN** `bindWx` 返回 `ErrUnionIDTakenByOther` 或 `ErrAccountMergeConflict`
- **THEN** 客户端必须 Toast 或对话框说明该微信已关联其他胖宝账号、无法合并
- **AND** 不得覆盖当前会话或切换账号

### Requirement: AuthRepository 必须暴露 bindApple 与 bindWx
The `AuthRepository` interface SHALL include `bindApple` and `bindWx` (or equivalent) calling the generalized backend bind endpoints with Bearer authorization.
`AuthRepository` 必须声明 `bindApple` 与 `bindWx`（或语义等价方法），由 `RemoteAuthRepository` 以 Bearer 调用 `POST /device/app/api/user/apple/bind` 与 `POST /device/app/api/user/wx/bindwx`；`bindWx` 必须适用于 Apple-only 账号，不得仅限用户名账号路径 `username/bindwx`。

#### Scenario: bindApple 请求体
- **WHEN** 用户触发绑定 Apple
- **THEN** 客户端必须 POST `{ identityToken, platform: ios }` 至 `apple/bind`
- **AND** 不得上传 Apple 邮箱

#### Scenario: bindWx 使用泛化端点
- **WHEN** Apple-only 用户触发绑定微信
- **THEN** 客户端必须 POST `{ jsCode, platform }` 至 `wx/bindwx`
- **AND** 不得要求用户先创建用户名密码

### Requirement: 账号管理界面必须提供绑定入口
The account management surface (`account_management_sheet` or equivalent) SHALL expose bind actions based on profile binding state on iOS.
账号管理界面（含 `account_management_sheet`）必须依据 profile 绑定状态展示：未绑微信 →「绑定微信」；未绑 Apple（iOS）→「绑定 Apple」；均已绑定 → 只读状态。

#### Scenario: account_management_sheet 展示绑定微信
- **WHEN** 已登录 Apple 用户打开账号管理且 `isWxBound=false`
- **THEN** 界面必须可见「绑定微信」入口

#### Scenario: account_management_sheet 展示绑定 Apple
- **WHEN** 已登录微信用户（iOS）打开账号管理且 `isAppleBound=false`
- **THEN** 界面必须可见「绑定 Apple」入口

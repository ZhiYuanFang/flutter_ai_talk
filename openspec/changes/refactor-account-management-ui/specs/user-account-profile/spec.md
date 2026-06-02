## ADDED Requirements

### Requirement: 客户端必须在已登录态拉取用户账号 profile
The client SHALL fetch the authenticated user account profile from `GET /device/app/api/user/profile` (Bearer) and expose `account` and `isWxBound` to account-management UI.

客户端在 Bearer 会话下必须调用 `GET /device/app/api/user/profile`，解析响应 `data` 中的 `account`（string，纯微信用户为空）与 `isWxBound`（boolean），并供账号管理与改密页读取。

#### Scenario: 已登录用户拉取 profile 成功
- **WHEN** 用户已登录且客户端请求 `GET /device/app/api/user/profile`
- **THEN** 客户端必须使用 Bearer 鉴权调用该接口
- **AND** 必须解析并暴露 `account` 与 `isWxBound` 供 UI 条件渲染

#### Scenario: 未登录时不得调用 profile
- **WHEN** 本地无有效 access token
- **THEN** 客户端不得发起 `GET /device/app/api/user/profile`
- **AND** 账号管理相关 UI 不得展示（由路由/登录态拦截）

#### Scenario: profile 请求失败
- **WHEN** `GET /device/app/api/user/profile` 返回业务错误或网络错误
- **THEN** 客户端必须向用户展示可读错误提示
- **AND** 不得崩溃；账号管理 Sheet 应允许用户关闭

#### Scenario: 纯微信用户 account 为空
- **WHEN** profile 返回 `isWxBound == true` 且 `account` 为空字符串或 null
- **THEN** 客户端必须将 `account` 规范化为空
- **AND** 账号管理 UI 不得展示「修改密码」入口

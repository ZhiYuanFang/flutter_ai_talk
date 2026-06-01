## ADDED Requirements

### Requirement: 客户端必须支持用户名账号注册与业务登录校验接口
The client SHALL support username registration and non-token business login endpoints.
客户端必须支持调用 `POST /device/app/api/user/username/register` 与 `POST /device/app/api/user/username/login`，并使用与主登录一致的账号密码规范化规则。

#### Scenario: 注册新账号成功
- **WHEN** 用户提交合法 `account` 与 `password`
- **THEN** 客户端必须调用 `POST /device/app/api/user/username/register`
- **AND** 成功后必须给出成功反馈并允许继续登录流程

#### Scenario: 调用业务登录接口成功
- **WHEN** 业务流程触发 `POST /device/app/api/user/username/login` 且接口成功
- **THEN** 客户端必须按业务成功处理
- **AND** 不得将该结果当作已建会话（不得写入 token）

### Requirement: Bearer 账号管理接口必须在已登录态可用
The client MUST expose authenticated username account-management operations.
客户端在 Bearer 会话下必须支持以下接口：`/user/username/bindwx`、`/user/username/bind_device`、`/user/username/change_password`、`/user/wx/create_username`，并在未登录时拒绝调用。

#### Scenario: 已登录用户修改密码
- **WHEN** 用户在已登录态提交旧密码与新密码
- **THEN** 客户端必须调用 `POST /device/app/api/user/username/change_password`（Bearer）
- **AND** 成功后必须提示操作成功

#### Scenario: 已登录用户绑定微信
- **WHEN** 用户提交 `jsCode` 与 `platform`
- **THEN** 客户端必须调用 `POST /device/app/api/user/username/bindwx`（Bearer）
- **AND** 成功后不得改变当前 token 持久化状态

#### Scenario: 已登录用户绑定设备号
- **WHEN** 用户提交 `deviceNo`
- **THEN** 客户端必须调用 `POST /device/app/api/user/username/bind_device`（Bearer）
- **AND** 若绑定目标为当前业务设备，客户端应刷新本地 `deviceNo` 缓存

#### Scenario: 微信已登录用户创建用户名密码
- **WHEN** 微信登录用户提交 `account` 与 `password`
- **THEN** 客户端必须调用 `POST /device/app/api/user/wx/create_username`（Bearer）
- **AND** 成功后应提示已补齐账号密码能力

### Requirement: 登录渠道状态必须兼容新增账号密码路径
The sign-in channel model MUST support username login while keeping backward compatibility.
客户端登录渠道状态必须新增 `username` 语义；历史 `device`、`wechat`、`unknown` 读取兼容保持不变，并确保新增路径不会误写 `device` 渠道。

#### Scenario: 用户通过账号密码登录成功
- **WHEN** `username_login` 建会话成功
- **THEN** 客户端必须将登录渠道写为 `username`
- **AND** 后续读取必须可用于资料保存分支判断

#### Scenario: 读取历史旧版本渠道值
- **WHEN** 本地存在 `device`、`wechat` 或空值
- **THEN** 客户端必须保持既有解析行为不变
- **AND** 不得因新增 `username` 破坏旧会话恢复

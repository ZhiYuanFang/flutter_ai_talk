## ADDED Requirements

### Requirement: 登录页仅提供微信登录入口
The login entry MUST expose WeChat sign-in as the only interactive sign-in method.
登录页必须仅展示微信登录入口，不得再展示胖宝号输入框、设备号登录按钮，或任何引导用户通过设备号完成登录的文案。

#### Scenario: 打开登录页时仅看到微信登录
- **WHEN** 未登录用户进入 `/login`
- **THEN** 页面只提供微信登录入口与必要的隐私政策入口
- **AND** 页面不得出现胖宝号输入框、设备号提交按钮或“默认使用胖宝号登录”等说明

#### Scenario: Web 登录页不再清理微信授权结果并提示设备号登录
- **WHEN** Web 用户从微信 OAuth 回调返回登录页且本地存在待消费的微信授权结果
- **THEN** 登录页不得清空该授权结果并提示“请使用胖宝号登录”
- **AND** 页面必须允许该授权结果继续用于微信登录流程

### Requirement: 微信登录必须成为唯一交互式建会话路径
The client SHALL use WeChat authorization as the only interactive sign-in path.
客户端必须以 `AuthRepository.signInWithWeChat()` 作为唯一交互式登录路径；当微信授权成功且网关返回有效 token 时，系统必须建立会话、持久化 token、刷新 `deviceNo` 缓存并进入主页。

#### Scenario: 微信登录成功后进入主页
- **WHEN** 用户在登录页完成微信授权且 `POST /device/app/api/login` 返回有效 `accessToken` 与 `refreshToken`
- **THEN** 客户端必须持久化会话并更新后续业务所需的 `deviceNo` 本地状态
- **AND** 客户端必须完成登录后跳转到主页而不是停留在登录页

#### Scenario: 微信授权失败时展示微信相关错误
- **WHEN** 微信授权被取消、未安装微信、缺少微信配置，或网关登录失败
- **THEN** 客户端必须向用户展示与微信登录相关的明确错误提示
- **AND** 提示内容不得再要求用户改用胖宝号登录

### Requirement: 设备号登录能力必须从客户端产品面移除
The client MUST remove device-number sign-in from the exposed product behavior.
客户端必须移除设备号登录这一产品能力，不得再通过页面交互、公开仓储接口或用户文档鼓励或支持用户使用 `POST /device/app/api/device_login` 完成登录。

#### Scenario: 用户文档与界面不再声明设备号登录是当前方式
- **WHEN** 用户查看登录页说明或 README 中的登录说明
- **THEN** 文档和界面必须声明当前支持微信登录
- **AND** 不得把胖宝号登录描述为默认、推荐或可用的当前登录方式

#### Scenario: 历史数据字段仍可继续使用
- **WHEN** 微信登录成功后的业务响应继续返回 `deviceNo` 供历史、画像或绑定功能使用
- **THEN** 客户端仍可把 `deviceNo` 作为后续业务标识使用
- **AND** 这不得被视为仍然保留了设备号登录能力

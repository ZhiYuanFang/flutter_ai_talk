## ADDED Requirements

### Requirement: 微信登录与用户体系

The system SHALL use WeChat as the only login method; Web and App MUST share the same user system and the same backend identity. OAuth authorization and code-to-token exchange SHALL be encapsulated by the server; the mobile/Web client only invokes the login entry provided by the product/backend documentation. 客户端不得在 OpenSpec 中硬编码未公开的 OAuth path。

#### Scenario: 同一用户跨端

- **WHEN** 用户分别在 Web 与 App 完成微信登录
- **THEN** 后端必须将其识别为同一用户体系下的身份（具体 unionid/openid 策略由服务端实现）

### Requirement: access_token 与 refresh 静默续期

The client SHALL attach `access_token` to protected API calls as agreed with the server (e.g. header); the system MUST support refresh-token-based silent renewal before access token expiry. 续期失败时的处理（清会话、回登录）由实现阶段在 `design` 补充；本需求要求 **必须具备静默续期能力**。

#### Scenario: 受保护接口携带凭证

- **WHEN** 客户端调用需要登录的 REST 接口
- **THEN** 请求必须携带当前有效的访问凭证（形式由与服务端约定为准）

### Requirement: 登出不调用服务端

The client SHALL clear local session and tokens on user sign-out without calling a server sign-out API. 产品已确认登出 **不需要** 调用服务端接口。

#### Scenario: 本地登出

- **WHEN** 用户确认登出或切换账号
- **THEN** 客户端必须清除本地会话状态且不得依赖服务端登出接口成功

### Requirement: 用户详情与 deviceNo 映射

The client SHALL call `GET /device/wx/api/detail` and map the returned `device_no` field to the in-app canonical field **`deviceNo` (string)** for all downstream API usage. 若 `device_no` 缺失或为空，客户端必须视为 **尚未绑定宝宝**（与「无有效 deviceNo」等价）。

#### Scenario: 映射 device_no

- **WHEN** `data` 中包含 `"device_no":"D202405080001"`
- **THEN** 客户端内部必须使用 `deviceNo == "D202405080001"` 参与后续 `deviceNo` Query/Body

### Requirement: 绑定与创建宝宝

The client SHALL support binding an existing baby with **POST** `/device/profile/api/bindwx` where **`data` 入参**（即请求体在业务层）包含 `deviceNo`. The client SHALL support creating a baby with **POST** `/device/profile/api/auto_save` with **`birthday`** and **`sex`** in `data`; the server response `data` MUST include the assigned **`deviceNo`** and this operation SHALL imply binding. 创建接口 **不得** 要求客户端预先传入 `deviceNo`。

#### Scenario: 绑定已有宝宝

- **WHEN** 用户输入已有宝宝 ID 并确认绑定
- **THEN** 客户端必须调用 `bindwx` 且请求体携带该 `deviceNo`

#### Scenario: 创建新宝宝

- **WHEN** 用户填写生日与性别并提交创建
- **THEN** 客户端必须调用 `auto_save` 且仅传 `birthday` 与 `sex`；成功后必须持久化返回的 `deviceNo` 供后续接口使用

### Requirement: 登录成功不等于可调用业务接口

The system SHALL treat WeChat login success and possession of `access_token` as insufficient for business APIs until a valid **`deviceNo`** is available (from user detail or after bind/create). 客户端必须在 **已登录但未绑定** 时引导用户前往绑定流程；在未登录时引导登录。

#### Scenario: 已登录未绑定拦截

- **WHEN** 用户已登录但 `deviceNo` 无效或为空
- **THEN** 客户端不得将需要 `deviceNo` 的接口当作已成功配置；必须展示「请绑定宝宝信息」类引导并支持跳转绑定

### Requirement: 默认进入主页与历史失败文案

The app SHALL allow entering the home screen for both logged-in and logged-out states as product default. When the history list request fails for a user who is **not logged in**, the UI SHALL still show the copy **「请绑定宝宝信息」**, and tapping that entry SHALL navigate to the **login** flow. When the user is **logged in but not bound**, a failed history list SHALL show **「请绑定宝宝信息」** and SHALL navigate the user to **baby binding**. 文案由产品固定为上述字符串（若需 i18n 后续变更）。

#### Scenario: 未登录历史失败点击

- **WHEN** 未登录且历史列表请求失败并展示「请绑定宝宝信息」
- **THEN** 用户点击该提示或入口后必须跳转至登录

#### Scenario: 已登录未绑定历史失败点击

- **WHEN** 已登录但未绑定且历史列表请求失败并展示「请绑定宝宝信息」
- **THEN** 用户点击后必须跳转至绑定宝宝信息流程

### Requirement: 点击事件范围与未登录拦截

For users who are **not logged in**, taps on **a history row**, **voice recording control**, or **send natural-language text** SHALL show a dialog or equivalent prompting login; non-interactive areas MAY show placeholders. 已登录未绑定时，上述交互必须引导 **绑定宝宝**（与历史失败跳转策略一致）。

#### Scenario: 未登录点击语音或发送

- **WHEN** 未登录用户点击语音录制或发送文案
- **THEN** 客户端必须拦截并弹框或等效提示前往登录，且不得发起 `/voice/text/chat` 请求

### Requirement: 设置页宝宝信息占位

When the user is **not logged in**, the settings screen baby profile section SHALL show placeholders instead of editable real profile fields. 已登录后的展示与编辑跳转行为由现有「设置中心 / 编辑宝宝页」产品继续演进，但至少须与「是否已绑定 deviceNo」一致且不展示伪造服务端数据。

#### Scenario: 未登录设置占位

- **WHEN** 用户未登录并打开设置中心
- **THEN** 宝宝信息区域必须展示占位符而非真实宝宝档案编辑表单

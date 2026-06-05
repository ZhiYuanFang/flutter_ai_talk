## ADDED Requirements

### Requirement: 服务端设备注册错误映射为宝宝ID语义

The client MUST map server messages that refer to unregistered devices into user-facing baby-ID copy. 当 API 或 WebSocket 返回含「设备未注册」「请先注册设备号」等后端字样的 `message` 时，客户端面向用户的 Toast **必须**展示 **「宝宝ID未绑定」**（或等价宝宝语义），**不得**原样展示「设备号未注册」等设备导向文案。

#### Scenario: 绑定不存在的宝宝 ID

- **WHEN** `bindwx` 返回业务失败且 `message` 含「设备未注册」或「请先注册设备号」
- **THEN** Toast **必须**显示「宝宝ID未绑定」
- **AND** **不得**显示「设备未注册，请先注册设备号」

#### Scenario: 其它接口同类错误

- **WHEN** 任意用户可见 API 失败 `message` 匹配设备未注册类模板（实现维护映射表）
- **THEN** Toast **必须**使用宝宝ID语义文案

### Requirement: WS 鉴权失败的用户文案

When displaying history WebSocket `type: error` messages to users after token sync, the client MUST map gateway device wording to baby-binding guidance where applicable. 历史 WebSocket 返回 `type: error` 且需 Toast 时，若 message 为「未绑定设备，无法订阅历史推送」，客户端**必须**映射为宝宝绑定/重新登录类宝宝语义（不得原样展示「未绑定设备」设备术语）；若 token 已 refresh 仍失败，Toast **不得**含「设备号未注册」等设备导向用语。

#### Scenario: WS error 帧 Toast

- **WHEN** 历史 WS 收到 `type: error` 且 `message` 为网关原文
- **THEN** Toast **必须**经 `normalizeUserFacingApiMessage`（或等价）再展示
- **AND** **不得**向用户展示「设备号未注册」

## MODIFIED Requirements

### Requirement: 用户可见术语统一为宝宝ID

The system MUST use "宝宝ID" terminology in user-facing copy instead of device terminology, including mapped API and WebSocket error messages. 在 App 用户可见的页面文案、提示文案与错误提示（**含** API envelope `message` 与 WS error 经映射后的 Toast）中，系统必须使用「宝宝ID」或等价宝宝语义，不得向用户展示「设备ID」「设备号未注册」「deviceNo」等设备导向术语。

#### Scenario: 绑定页面展示宝宝ID术语

- **WHEN** 用户进入宝宝信息绑定页面并查看输入提示与操作文案
- **THEN** 页面展示「宝宝ID」相关文案，不出现「设备ID」字样

#### Scenario: 设置与提示文案不暴露设备术语

- **WHEN** 用户在设置页查看绑定状态、切换账号提示或接收相关错误提示
- **THEN** 所有面向用户的文案使用宝宝语义，不出现「设备」或「deviceNo」术语

#### Scenario: API 失败 Toast 使用宝宝语义

- **WHEN** 绑定宝宝 ID 失败且服务端 message 含设备未注册语义
- **THEN** Toast **必须**为「宝宝ID未绑定」

## ADDED Requirements

### Requirement: 用户可见术语统一为宝宝ID
The system MUST use "宝宝ID" terminology in user-facing copy instead of device terminology.
在 App 用户可见的页面文案、提示文案与错误提示中，系统必须使用“宝宝ID”或等价宝宝语义，不得向用户展示“设备ID”“设备”“deviceNo”等设备导向术语。

#### Scenario: 绑定页面展示宝宝ID术语
- **WHEN** 用户进入宝宝信息绑定页面并查看输入提示与操作文案
- **THEN** 页面展示“宝宝ID”相关文案，不出现“设备ID”字样

#### Scenario: 设置与提示文案不暴露设备术语
- **WHEN** 用户在设置页查看绑定状态、切换账号提示或接收相关错误提示
- **THEN** 所有面向用户的文案使用宝宝语义，不出现“设备”或“deviceNo”术语

### Requirement: 协议字段保持兼容
The system SHALL keep protocol field names unchanged while updating user-facing copy.
在完成用户可见文案统一的同时，系统必须保持 API 协议字段与内部协议映射不变（例如 `deviceNo` / `device_no`），避免后端兼容性风险。

#### Scenario: 文案调整后协议请求不变
- **WHEN** 用户执行绑定、创建、历史查询等依赖标识编码的操作
- **THEN** 客户端仍按现有协议发送和解析 `deviceNo` / `device_no` 字段

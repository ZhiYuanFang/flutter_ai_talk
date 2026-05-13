## ADDED Requirements

### Requirement: 单宝宝信息展示

The system SHALL display exactly one linked baby’s summary for the signed-in account (server or mock fields). 系统必须展示与当前登录账户关联的**唯一**宝宝信息（字段由服务端或 Mock 提供）。

#### Scenario: 已登录用户查看设置

- **WHEN** 用户在已登录状态下打开设置中心
- **THEN** 系统必须展示仓库返回的该宝宝摘要字段

### Requirement: 设置内打开隐私政策

The system SHALL open the privacy policy URL in-app from Settings using the same approach as login (WebView on mobile; embedded web on Web). 设置中心必须提供隐私政策入口，打开方式与登录页一致（移动端 WebView；Web 端页内嵌入）。

#### Scenario: 从设置打开隐私政策

- **WHEN** 用户在设置中选择隐私政策
- **THEN** 系统必须在应用内打开所配置的隐私政策 URL

### Requirement: 账号生命周期操作

The system SHALL surface switch-account and deregister actions and MUST require confirmation before destructive steps (local session teardown minimum). 设置中心必须向用户展示 **切换账号** 与 **注销账户** 操作。破坏性操作在执行不可逆的本地会话清理前**必须**至少经过用户确认；远程销号行为在对接后端后须遵循接口契约。

#### Scenario: 切换账号

- **WHEN** 用户选择切换账号
- **THEN** 系统必须按认证设计清除或轮换会话，并返回登录流程

#### Scenario: 注销前确认

- **WHEN** 用户选择注销账户
- **THEN** 系统在继续前必须展示确认步骤

### Requirement: 主题默认值与自定义背景

The system SHALL default theme tones from baby sex (male deep blue, female red) and SHALL let users override background color in Settings with custom background taking precedence until cleared. 系统必须根据宝宝性别推导默认主题色：**男 → 深蓝系**，**女 → 红色系**（具体色值由实现定义）。用户必须能在设置中选择自定义背景色；一旦保存自定义背景，其在产品约定的一级体验表面上必须优先于性别默认背景，直至用户清除或修改。

#### Scenario: 男性默认主题

- **WHEN** 宝宝记录为男性且未保存自定义背景
- **THEN** 应用必须应用深蓝取向的默认主题

#### Scenario: 自定义背景优先

- **WHEN** 用户保存了自定义背景色
- **THEN** 该颜色必须作为用户可见的背景偏好使用，直至被清除或更改

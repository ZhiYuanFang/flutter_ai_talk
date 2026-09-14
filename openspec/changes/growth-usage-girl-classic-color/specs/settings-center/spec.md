## MODIFIED Requirements

### Requirement: 主题默认值与自定义背景

The system SHALL default theme tones from baby sex (male deep blue, female green `#2CB771`) and SHALL let users override background color in Settings with custom background taking precedence until cleared. 系统必须根据宝宝性别推导默认主题色：**男 → 深蓝系**，**女 → 绿色系（`#2CB771`）**。用户必须能在设置中选择自定义背景色；一旦保存自定义背景，其在产品约定的一级体验表面上必须优先于性别默认背景，直至用户清除或修改。

#### Scenario: 男性默认主题

- **WHEN** 宝宝记录为男性且未保存自定义背景
- **THEN** 应用必须应用深蓝取向的默认主题

#### Scenario: 女性默认主题

- **WHEN** 宝宝记录为女性且未保存自定义背景
- **THEN** 应用必须应用基于 `#2CB771` 的默认主题

#### Scenario: 自定义背景优先

- **WHEN** 用户保存了自定义背景色
- **THEN** 该颜色必须作为用户可见的背景偏好使用，直至被清除或更改

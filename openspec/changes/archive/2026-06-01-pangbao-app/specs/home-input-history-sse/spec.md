## ADDED Requirements

### Requirement: 主输入方式按平台区分

The system SHALL provide a dominant primary input on home: press-and-hold voice with STT on Android/iOS (text-only payload), and text submit on Web without voice capture for that control. 系统必须在主页提供视觉显著的主输入区。在 Android 与 iOS 上，用户必须通过**按住开始、松手结束**完成一次采集；系统必须使用原生或系统支持的语音识别将语音转为文字，且仅将转写后的文本发往指令接口（或 Mock 等价物）。在 Web 上，系统不得对该主控件使用语音采集；用户必须以文本输入自然语言并**显式提交**。

#### Scenario: 移动端语音采集结束

- **WHEN** 用户在 Android 或 iOS 上说完话并松开语音控件
- **THEN** 系统必须获得转写文本并以该文本为载荷调用对外的指令动作

#### Scenario: Web 文本提交

- **WHEN** 用户在 Web 上输入文字并提交
- **THEN** 系统必须使用与移动端相同的指令载荷形状，以所输入文字调用该指令动作

### Requirement: 历史区布局与排序

The system SHALL render the history panel above the primary input with newest-at-bottom ordering, upward fade, and non-increasing type sizes toward the top (subject to accessibility minima). 系统必须在主输入区上方渲染历史记录区。初始数据必须按服务端契约加载（M1 允许 Mock）。记录顺序必须满足：**时间上最新的一条固定在面板底部**；较旧记录位于更高处，自下而上呈现**纵向渐隐**，且越往上**字号单调不增**（无障碍规定的最小字号除外）。

#### Scenario: 初次加载后最新在底部

- **WHEN** 主页加载历史数据完成
- **THEN** 时间最新的一条必须锚定在历史堆栈的底部

#### Scenario: 自下而上的视觉层次

- **WHEN** 同时可见多条历史
- **THEN** 距底部越远的项必须更淡，且字号不得大于更靠近底部的项

### Requirement: 通过 SSE 合并最新历史

The system SHALL maintain SSE (or mock-equivalent stream) on the active home screen and merge server-pushed latest records into the history panel. 系统在主页激活期间必须维持 SSE 订阅（或与消费者契约一致的 Mock 流），当服务端推送表示**最新一条**记录的更新时，必须插入或替换历史区中的对应最新项。

#### Scenario: 推送驱动界面更新

- **WHEN** 收到携带新最新历史记录的 SSE 事件
- **THEN** 历史区必须将该记录反映为底部最新一条，且无需用户手动全量刷新

### Requirement: 从主页进入二级功能

The system SHALL expose navigation controls to Trends near the upper-right of the primary input and Settings at the home header’s top-right. 系统必须提供打开趋势中心的控件，位置在**主输入区右上方附近**；必须在主页 AppBar 或等效顶栏**右上角**提供打开设置中心的控件。

#### Scenario: 进入趋势中心

- **WHEN** 用户点击趋势入口
- **THEN** 应用必须导航至趋势中心路由

#### Scenario: 进入设置中心

- **WHEN** 用户点击设置入口
- **THEN** 应用必须导航至设置中心路由

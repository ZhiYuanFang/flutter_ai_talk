## MODIFIED Requirements

### Requirement: 历史区布局与排序

The system SHALL render the history panel above the primary input with newest-at-bottom ordering, upward visual weakening (via top gradient and/or non-increasing type emphasis), and non-increasing type sizes toward the top (subject to accessibility minima). 系统必须在主输入区上方渲染历史记录区。初始数据必须按服务端契约加载。记录顺序必须满足：**时间上最新的一条固定在面板底部**；较旧记录位于更高处，自下而上呈现**变弱**效果（允许以列表**顶部渐变**与字号/颜色层次实现，不必对每条使用整行透明度蒙层），且越往上**字号单调不增**（无障碍规定的最小字号除外）。

#### Scenario: 初次加载后最新在底部

- **WHEN** 主页加载历史数据完成
- **THEN** 时间最新的一条必须锚定在历史堆栈的底部

#### Scenario: 自下而上的视觉层次

- **WHEN** 同时可见多条历史
- **THEN** 距底部越远的项必须在视觉上更弱（顶部渐变或字号/颜色），且字号不得大于更靠近底部的项

## MODIFIED Requirements

### Requirement: 从主页进入二级功能

The system SHALL expose navigation to Trends via a control in the home AppBar actions (alongside history WebSocket status and Settings), and SHALL expose Settings at the home AppBar top-right. 系统必须在主页 **AppBar 右侧操作区**提供打开**趋势中心**的入口（与历史 WebSocket 状态、设置并列）；**设置**仍位于 AppBar 右上角区域（建议为最右侧一项）。

#### Scenario: 进入趋势中心

- **WHEN** 用户点击 AppBar 上的趋势入口
- **THEN** 应用必须导航至趋势中心路由

#### Scenario: 进入设置中心

- **WHEN** 用户点击设置入口
- **THEN** 应用必须导航至设置中心路由

#### Scenario: 主输入区不再承载趋势按钮

- **WHEN** 用户查看主页底部主输入区（语音球或文字输入）
- **THEN** 该区域不得再显示独立的「趋势」浮动按钮，以免与按住说话或字幕区争抢空间

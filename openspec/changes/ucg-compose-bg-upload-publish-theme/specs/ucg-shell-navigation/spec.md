## MODIFIED Requirements

### Requirement: UCG shell SHALL provide five-item bottom navigation

UCG page SHALL provide bottom navigation with items: 广场、宝藏（若启用）、+（发布）、消息、我的。中间「+」SHALL open compose flow without switching to a permanent fifth tab index. Short tap on「+」MUST open media entry flow per draft state. After a **new post** is successfully published from compose, the shell MUST switch selection to「我的」.

底栏五栏不变；**新帖**发表成功后须自动选中「我的」。

#### Scenario: 新帖发表后选中我的
- **WHEN** 用户通过「+」发表新帖且 compose 返回 published 结果
- **THEN** 底栏 SHALL 选中「我的」
- **AND** IndexedStack SHALL 展示个人主页内容

#### Scenario: 编辑帖返回不打乱 Tab
- **WHEN** 用户从详情编辑帖子并返回
- **THEN** 底栏 SHALL 保持进入编辑前的 Tab 选中态

#### Scenario: 点击加号进入 compose 后取消
- **WHEN** 用户通过「+」进入 compose 后取消且未发表新帖
- **THEN** App SHALL 恢复先前 Tab 选中态

#### Scenario: 切换广场与我的
- **WHEN** 用户点击底部「我的」
- **THEN** 壳 SHALL 显示个人页内容，且底部「我的」为选中态

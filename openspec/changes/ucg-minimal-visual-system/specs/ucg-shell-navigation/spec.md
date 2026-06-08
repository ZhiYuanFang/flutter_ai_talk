## MODIFIED Requirements

### Requirement: UCG shell SHALL provide five-item bottom navigation

UCG page（PageView index 1）SHALL provide bottom navigation with items: 广场、宝藏、+（发布）、消息、我的。中间「+」SHALL open compose flow without switching to a permanent fifth tab index. Bottom navigation MUST use `ucg-visual-system` **flat embedded bar** styling (full-width on `shellColor`, lightweight primary selection, no glass pill), not default Material `BottomNavigationBar` and not glass dock.

UCG 壳必须提供底部五栏：广场、宝藏、发布（中间动作槽）、消息、我的。底栏必须为全宽扁平嵌入 `shellColor`，选中态轻量（颜色+字重）；中间发布入口与两侧 tab 同构，无渐变圆按钮。

#### Scenario: 切换广场与我的
- **WHEN** 用户点击底部「我的」
- **THEN** 壳 SHALL 显示个人页内容，且底部「我的」为选中态（primary 色+字重，无底色 pill）

#### Scenario: 点击加号打开发布
- **WHEN** 用户点击底部「发布」
- **THEN** App SHALL 打开发布页（全屏 route），且返回后 SHALL 恢复先前 Tab 选中态；发布入口 SHALL NOT 使用渐变圆形强调按钮

#### Scenario: 底栏嵌入 shell 无玻璃 pill
- **WHEN** 用户查看 UCG 壳任意 Tab
- **THEN** 底部五栏 SHALL 全宽嵌入 `shellColor`，且 SHALL NOT 呈现悬浮磨砂 pill 或明显分层色块底栏

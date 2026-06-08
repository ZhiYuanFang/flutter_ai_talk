## MODIFIED Requirements

### Requirement: UCG shell SHALL provide bottom navigation with optional treasure tab

UCG page（PageView index 1）SHALL provide bottom navigation. When `kUcgTreasureEnabled` is `true`, items MUST be: 广场、宝藏、+（发布）、消息、我的（五栏）。When `kUcgTreasureEnabled` is `false`, items MUST be: 广场、+（发布）、消息、我的（四栏），且 MUST NOT 展示「宝藏」入口。中间「+」SHALL open compose flow without switching to a permanent tab index. Bottom navigation MUST use `ucg-visual-system` **flat embedded bar** styling (full-width on `shellColor`, lightweight primary selection, no glass pill), not default Material `BottomNavigationBar` and not glass dock.

UCG 壳底栏在宝藏开关开启时为五栏，关闭时为四栏（无宝藏）；中间发布为动作槽，不切 stack index。

#### Scenario: 切换广场与我的（宝藏关闭）
- **WHEN** `kUcgTreasureEnabled` 为 `false` 且用户点击底部「我的」
- **THEN** 壳 SHALL 显示个人页内容，且底部「我的」为选中态
- **AND** 底栏 SHALL NOT 展示「宝藏」项

#### Scenario: 点击加号打开发布
- **WHEN** 用户点击底部「发布」
- **THEN** App SHALL 打开发布页（全屏 route），且返回后 SHALL 恢复先前 Tab 选中态

#### Scenario: 底栏嵌入 shell 无玻璃 pill
- **WHEN** 用户查看 UCG 壳任意 Tab
- **THEN** 底部导航 SHALL 全宽嵌入 `shellColor`，且 SHALL NOT 呈现悬浮磨砂 pill

## REMOVED Requirements

### Requirement: 宝藏 Tab SHALL show placeholder

**Reason**: 首版临时隐藏宝藏入口，避免占位页曝光；下版恢复开关后重新适用原占位要求。

**Migration**: 将 `kUcgTreasureEnabled` 设回 `true` 并验证 `UcgTreasurePlaceholder` 仍可访问。

#### Scenario: 进入宝藏
- **WHEN** 用户选中「宝藏」
- **THEN** （本 change 期间不适用）

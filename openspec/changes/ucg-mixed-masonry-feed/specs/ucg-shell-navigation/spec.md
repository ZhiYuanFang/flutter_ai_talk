## MODIFIED Requirements

### Requirement: UCG shell bottom navigation SHALL include compose entry

UCG page SHALL provide bottom navigation with 广场、+（发布）、消息、我的（及可选宝藏）。中间「+」SHALL open compose flow without switching tab index. **`showComposeEntry` MUST be true** on `UcgBottomDock`. Short tap on「+」MUST open compose per `ucg-compose-post` (direct `UcgComposeScreen`, draft-first). After successful **new post** publish, shell MUST switch to「我的」. The 广场 tab MUST NOT show a floating action button for debate compose.

Shell MUST 恢复 Dock 发帖；广场 MUST NOT 有辩论 FAB。

#### Scenario: Dock 展示发帖入口

- **WHEN** 用户进入 UCG Shell
- **THEN** 底栏 SHALL 展示「+」发帖按钮
- **AND** 短按 SHALL 进入 compose 流程

#### Scenario: 广场无 FAB

- **WHEN** 用户在广场 Tab 浏览 Feed
- **THEN** UI MUST NOT 展示 `FloatingActionButton` 发帖入口
- **AND** MUST NOT 打开 `UcgDebateComposeScreen`

## REMOVED Requirements

### Requirement: Square tab SHALL use FAB for debate compose

**Reason**: Compose unified under Dock + per product direction.

**Migration**: Remove FAB from `UcgSquareTab`; use Dock handler only.

## REMOVED Requirements

### Requirement: 右侧拉条 SHALL 仅在喂养页展示

**Reason**: 产品取消喂养页贴边拉条；进入广场改由横滑。  
**Migration**: 从喂养页横滑进入 page 2；删除 `UcgEnterSquareTab` 挂载。

### Requirement: Enter-square pull tab SHALL show UCG unread indicator on feeding page

**Reason**: 未读点绑定「进入广场」拉条；拉条删除后该指示一并移除。  
**Migration**: 未读仍由 UCG 壳消息 Tab（或等价）展示；喂养页不再显示广场未读拉条红点。WS 乐观递增与 HTTP baseline 逻辑若仍服务 UCG 壳则保留，仅不再驱动拉条 UI。

### Requirement: Left-edge companion pull tab SHALL show on feeding page

**Reason**: 产品取消喂养页贴边拉条；进入陪伴改由横滑 / tip「对话」/ pager。  
**Migration**: 从喂养页横滑进入 page 0；删除 `UcgEnterCompanionTab` 挂载。

## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with exactly three pages: index 0 SHALL be the smart companion page; index 1 SHALL be the existing feeding `HomeScreen` (default landing); index 2 SHALL be the UCG shell widget. The companion page MUST NOT be built or mounted until the user first navigates to index 0. The UCG shell widget MUST NOT be built or mounted until the user first navigates to index 2. Cold start on index 1 MUST NOT instantiate companion UI or `UcgShell`, MUST NOT run square feed initial load, MUST NOT connect Clinic WS solely due to `/home` mount, and MUST NOT trigger UCG location consent. Switching MUST NOT destroy feeding page State (`AutomaticKeepAliveClientMixin` or equivalent). While the home input mode dock (or tip panel) is being dragged for reposition, the PageView MUST temporarily disable horizontal page scrolling; after drag ends, horizontal scrolling MUST be re-enabled. Feeding-page edge pull tabs MUST NOT be required for navigation.

App `/home` SHALL 使用三页 PageView：page 0 智能陪伴，page 1 喂养（默认着陆），page 2 UCG 壳。陪伴与 UCG 均 MUST NOT 在首次进入对应页之前 build/mount；冷启动停留喂养时 MUST NOT 实例化陪伴/`UcgShell`。dock/tip 拖动期间 MUST 暂停横滑。进入侧页 **不得** 依赖喂养页贴边拉条。

#### Scenario: 默认进入喂养页

- **WHEN** 用户导航至 `/home`
- **THEN** PageView SHALL 显示 page 1（喂养 HomeScreen），且 SHALL NOT 默认停留在陪伴页或 UCG 页
- **AND** 陪伴页与 `UcgShell` MUST NOT 被构建

#### Scenario: 从 UCG 返回喂养

- **WHEN** 用户在 UCG 页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 1

#### Scenario: 从陪伴返回喂养

- **WHEN** 用户在陪伴页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 1

#### Scenario: dock 拖动期间暂停横滑

- **WHEN** 用户在 page 1 拖动 `HomeInputModeDock` reposition
- **THEN** PageView MUST NOT 响应横滑切页，直至拖动结束

#### Scenario: 首次横滑进入广场才挂载 UCG

- **WHEN** 用户从喂养页横滑首次进入 page 2
- **THEN** App SHALL 挂载 `UcgShell` 并开始广场首屏加载
- **AND** 在此之前 MUST NOT 构建 `UcgShell`

#### Scenario: 首次横滑进入陪伴才挂载陪伴页

- **WHEN** 用户从喂养页横滑首次进入 page 0
- **THEN** App SHALL 挂载智能陪伴页
- **AND** 在此之前 MUST NOT 构建陪伴页

## ADDED Requirements

### Requirement: Feeding page MUST NOT show companion or square edge pull tabs

While PageView is on the feeding page, the client MUST NOT render left-edge「进入陪伴」or right-edge「进入广场」expandable pull tabs (or equivalent edge strips). 喂养页 **不得** 渲染左缘「进入陪伴」或右缘「进入广场」可展开拉条（或等价贴边条）。

#### Scenario: 喂养页无拉条

- **WHEN** PageView 位于喂养页（index 1）
- **THEN** UI MUST NOT 展示「进入陪伴」拉条
- **AND** MUST NOT 展示「进入广场」拉条

### Requirement: Feeding page MUST allow horizontal swipe into companion and UCG

While on the feeding page and PageView scrolling is not blocked by an in-progress dock/tip drag (or equivalent existing guard), the user MUST be able to horizontally swipe to the companion page and to the UCG page. 喂养页在未被 dock/tip 拖动等既有禁滑守卫挡住时，用户 **必须** 能横滑进入陪伴页与 UCG 页。

#### Scenario: 横滑进入陪伴

- **WHEN** 用户在喂养页且 PageView 可滑
- **AND** 用户向陪伴方向横滑完成一页
- **THEN** PageView MUST 到达陪伴页（index 0）

#### Scenario: 横滑进入 UCG

- **WHEN** 用户在喂养页且 PageView 可滑
- **AND** 用户向 UCG 方向横滑完成一页
- **THEN** PageView MUST 到达 UCG 页（index 2）

## ADDED Requirements

### Requirement: Prediction portrait SHALL show a UCG square EdgeDock ball when eligibility is qualified

When `kUcgHomePagerEnabled` is true, the user is on the home smart-prediction page in **portrait**, and `ucgEligibilityStateProvider` reports `qualified=true`, the client MUST show a draggable EdgeDock square-entry ball (peek / engage / floating via `EdgeDockShell`). The ball MUST NOT appear in landscape, on the feeding page, or when `qualified` is not true (including loading and fail-closed). The ball face MUST be graphic-only (icon on glass circle) with NO text label or caption overlay.

当 UCG 主壳开启、用户在预测页竖屏且 eligibility `qualified=true` 时，客户端 **必须** 展示可拖 EdgeDock 广场入口球；横屏、喂养、未合格（含加载/fail-closed）**必须 NOT** 展示；球面 **必须** 纯图形、无文字。

#### Scenario: 合格后预测竖屏见球

- **WHEN** 用户在主壳预测页竖屏且 `qualified=true`
- **THEN** 客户端 MUST 展示广场 EdgeDock 球

#### Scenario: 未合格不展示

- **WHEN** `qualified` 不为 true
- **THEN** 预测页 MUST NOT 展示广场球

#### Scenario: 横屏与喂养不展示

- **WHEN** 设备为横屏或用户在喂养页
- **THEN** 客户端 MUST NOT 展示广场球

#### Scenario: 球面无文字

- **WHEN** 广场球可见（含 peek）
- **THEN** 球面 MUST NOT 展示文字标签或旁挂 caption

### Requirement: Square EdgeDock ball tap SHALL navigate to the UCG pager page

An interactive tap on the square EdgeDock ball (engaged / floating interactive tap path; NOT peek light-tap) MUST call `homePagerRequestProvider.requestPage(HomePagerPage.ucg)` (or equivalent) so the home PageView animates to the UCG page. While the pointer occupies the EdgeDock hit target for drag/reposition, the client MUST block home PageView horizontal swipes until release/cancel (same pattern as prediction voice EdgeDock).

交互点按广场球 **必须** 请求切到 UCG 页；拖动热区占用期间 **必须** 禁止主壳 PageView 横滑直至抬起。

#### Scenario: 点按进广场

- **WHEN** 用户对广场球完成 interactive 点按且 `qualified=true`
- **THEN** 主壳 PageView MUST 动画到 UCG 页

#### Scenario: 拖球不切页

- **WHEN** 用户在广场球热区按下并拖动 reposition
- **THEN** 在指针抬起前 PageView MUST NOT 因该手势横滑切页

### Requirement: Square ball unread indicator SHALL mirror message-tab unread without a count

When `ucgUnreadCountProvider` (or the same aggregate used by the UCG bottom「消息」tab badge) is greater than zero, the square ball MUST show a small red-dot indicator **inside** a corner of the ball circle with NO numeric badge. When unread is zero, the red dot MUST NOT show. The corner MUST flip with `DockEdge` so that in edge peek the dot remains on the on-screen half of the ball: right-edge peek → inward top-left; left-edge peek → inward top-right; floating → default top-right (top/bottom edges MUST use an inward corner). Clearing unread via existing message/inbox sync MUST clear the ball dot without a separate read model.

未读合计 > 0 时广场球 **必须** 在球内角落显示无数字红点，并与消息 tab 同源；贴边 peek 时红点角落 **必须** 朝屏内换位；未读清零后红点 **必须** 消失。

#### Scenario: 有未读显示红点

- **WHEN** 聚合未读 > 0 且广场球可见
- **THEN** 球 MUST 显示无数字红点

#### Scenario: 无未读无红点

- **WHEN** 聚合未读 = 0 且广场球可见
- **THEN** 球 MUST NOT 显示红点

#### Scenario: 右贴边 peek 红点在屏内

- **WHEN** 球为右侧 peek 且有未读
- **THEN** 红点 MUST 落在球内朝屏内的角落（左上），不得落在屏外半圆

#### Scenario: 左贴边 peek 红点在屏内

- **WHEN** 球为左侧 peek 且有未读
- **THEN** 红点 MUST 落在球内朝屏内的角落（右上），不得落在屏外半圆

### Requirement: Square EdgeDock placement SHALL default to right-center peek and persist last placement

On first launch with no stored placement, the square ball MUST initialize as `DockEdge.right` with vertical `along` ≈ 0.5 in edge peek. After the user repositions the ball, the client MUST persist edge+along or floating free-center in a dedicated prefs namespace (MUST NOT reuse prediction-voice dock keys). Subsequent mounts MUST restore the last saved placement when valid.

无存档时 **必须** 默认右侧纵向居中 peek；用户拖放后 **必须** 用独立 prefs 记住；再次进入 **必须** 还原有效存档。

#### Scenario: 首启默认右中 peek

- **WHEN** 无广场球位置 prefs 且球首次展示
- **THEN** 球 MUST 以右侧、along≈0.5 的 peek 出现

#### Scenario: 记住贴边位置

- **WHEN** 用户将球拖到左侧某 along 并松手吸附
- **THEN** 下次进入预测竖屏 MUST 还原为该左侧 along

#### Scenario: 记住浮空位置

- **WHEN** 用户将球置于 floating 并松手
- **THEN** 下次进入 MUST 还原该 free-center（在有效范围内）

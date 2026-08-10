## ADDED Requirements

### Requirement: Grid prediction event cards SHALL start the same add-event flow as feeding home

When the smart prediction page is in grid/waterfall layout, activating a prediction event card (excluding the forecast toggle control) MUST start the same add-event flow as tapping that event on the feeding home event grid: if the event has children in the catalog, the client MUST present the event catalog picker and continue only with the selected leaf; then the client MUST apply the same type-specific add behavior for `time` / `one` / `number` (including remote/device gate, active-timing guard for timing events, and number sheet when required) and MUST submit via the existing history add API. After a successful add, the client MUST remain on the smart prediction page (MUST NOT force-navigate to feeding solely because of this tap). Activating the forecast toggle MUST NOT start the add-event flow. List/non-compact cards are out of scope for this requirement.

智能预测页处于网格/瀑布流布局时，激活事件卡片（不含推演开关）**必须** 启动与喂养主页事件格相同的加事件流程：有子事件时 **必须** 弹出目录选择并仅对所选叶子继续；随后 **必须** 按 `time`/`one`/`number` 走同一类型逻辑（含远程/设备门闩、计时中守卫、数量 sheet）并经现有历史添加 API 提交；成功后 **必须** 留在智能预测页（**不得** 仅因该点击强制切到喂养页）；操作推演开关 **不得** 触发加事件；非 compact 列表卡不在本要求范围内。

#### Scenario: 网格父事件选叶子后添加

- **WHEN** 用户在网格布局点击某父事件卡片且 catalog 有子事件
- **THEN** 客户端 MUST 展示事件目录选择 sheet
- **AND** 用户选定叶子后 MUST 按该叶子类型执行添加（与喂养主页一致）
- **AND** 成功后 MUST 仍停留在智能预测页

#### Scenario: 网格叶子直接添加

- **WHEN** 用户在网格布局点击无子事件的叶子卡片且事件类型为 time 或 one
- **THEN** 客户端 MUST 先弹出确认是否添加该事件
- **AND** 用户确认后 MUST 按该事件类型执行添加
- **AND** MUST NOT 因此改变喂养主页事件格（喂养页无此确认）

#### Scenario: 网格 number 叶子不经确认

- **WHEN** 用户在网格布局点击无子事件且类型为 number 的叶子卡片
- **THEN** 客户端 MUST NOT 先弹出「是否添加」确认
- **AND** MUST 直接进入数量录入 sheet（与喂养主页一致）

#### Scenario: picker 选出的叶子不经确认

- **WHEN** 用户在网格布局点击父事件并在目录中选定叶子
- **THEN** 客户端 MUST NOT 再弹出「是否添加」确认
- **AND** MUST 按该叶子类型执行添加

#### Scenario: 推演开关不触发添加

- **WHEN** 用户仅切换网格卡片上的推演开关
- **THEN** 客户端 MUST NOT 因此打开子事件选择或提交历史添加

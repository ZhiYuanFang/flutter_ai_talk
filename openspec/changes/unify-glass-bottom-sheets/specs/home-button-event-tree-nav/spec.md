## MODIFIED Requirements

### Requirement: 方案 B 单 Sheet 内部导航

The catalog picker sheet SHALL use a single bottom sheet with an internal navigation stack, breadcrumb title, and unbounded depth, presented inside a glassmorphism panel via the shared glass overlay entry. 子目录选择必须采用**单个** Bottom Sheet：内部维护路径栈、标题展示面包屑（如 `A › B`）、支持**无限层级**；有子项行必须显示 `chevron_right`；选中叶子必须 `pop` 返回该 `EventDefinition` 并关闭 Sheet；Sheet 可见容器 MUST 为玻璃拟态（`HistoryEditGlassPanel`），MUST NOT 使用实心主题色 Material 底栏。

#### Scenario: 进入子级

- **WHEN** 用户在 Sheet 内点击仍有子节点的一项
- **THEN** 必须在**同一 Sheet 内**更新列表为该项的子节点，且标题必须反映当前路径

#### Scenario: 返回上一级

- **WHEN** 当前路径深度大于 1 且用户点击返回
- **THEN** 必须回到上一级子列表，不得关闭 Sheet

#### Scenario: 选中叶子

- **WHEN** 用户在 Sheet 内点击无子节点的一项
- **THEN** Sheet 必须关闭并返回该事件；外层必须调用既有 `_onEventButtonTap` 完成记录

#### Scenario: 叶子选定后 number 二级页

- **WHEN** Sheet 返回的叶子 `eventType` 为 `number`
- **THEN** Sheet 关闭后必须再打开既有 number 二级 BottomSheet，行为与变更前一致

#### Scenario: 玻璃目录选择器外观

- **WHEN** 用户因点击有子节点的根/文件夹而打开目录 Sheet
- **THEN** 用户 MUST 看到磨砂玻璃面板、浅色前景文字与面包屑标题，视觉 MUST 与主页历史编辑 Sheet 家族一致

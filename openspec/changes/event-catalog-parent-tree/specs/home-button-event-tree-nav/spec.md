## ADDED Requirements

### Requirement: 按钮模式仅展示根节点

The home button input grid SHALL display only root catalog entries that are either navigable folders or directly recordable leaves. 首页按钮模式网格必须仅展示**根节点**（`parentId` 为空）；其中必须包含「有子节点」的文件夹，以及「无子节点且具备合法 `eventType`」的可记录叶子；无子且无合法 `eventType` 的根节点不得出现在网格中。

#### Scenario: 扁平 legacy 目录

- **WHEN** 全部事件均无 `parentId`、均无子节点、且 defines 合法 `eventType`
- **THEN** 网格展示集合与变更前「`hasValidEventType` 过滤后的全量列表」必须一致

#### Scenario: 多级目录

- **WHEN** 存在 `parentId` 非空的子事件
- **THEN** 网格不得展示该子事件，仅展示根节点

### Requirement: 有子节点一律进入目录 Sheet

When the user taps a root or folder event that has children, the client MUST open the catalog picker sheet and MUST NOT call `addHistoryEvent` until a leaf is selected. 用户点击**有子节点**的事件时，客户端必须打开目录选择 Sheet 并**不得**调用 `add`；即使该事件配置了 `eventType` 也不得直接记录。

#### Scenario: 文件夹根节点

- **WHEN** 用户点击有子节点的根事件 R
- **THEN** 必须打开方案 B 单 Sheet 展示 R 的子项，且不得发起 add

#### Scenario: 可记录叶子根节点

- **WHEN** 用户点击无子节点且 `eventType` 合法的根事件 L
- **THEN** 必须直接进入既有 `time` / `one` / `number` 记录流程，不得打开 Sheet

### Requirement: 方案 B 单 Sheet 内部导航

The catalog picker sheet SHALL use a single bottom sheet with an internal navigation stack, breadcrumb title, and unbounded depth. 子目录选择必须采用**单个** Bottom Sheet：内部维护路径栈、标题展示面包屑（如 `A › B`）、支持**无限层级**；有子项行必须显示 `chevron_right`；选中叶子必须 `pop` 返回该 `EventDefinition` 并关闭 Sheet。

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

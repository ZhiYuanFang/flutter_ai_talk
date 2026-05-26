## ADDED Requirements

### Requirement: Persist usage count on successful button-mode add

The system SHALL increment a local usage counter for the recorded event id when a button-mode history add succeeds. 系统 MUST 在按钮模式 **成功添加** 历史记录后，对 **实际落库的 eventId** 本地计数 +1 并持久化；`addHistoryEvent` 失败、用户取消 number Sheet、同 event 已在计时中等 **未成功落库** 路径 MUST NOT 计数。

#### Scenario: Successful add increments count

- **WHEN** 用户通过底部按钮（含目录 Picker 选中的叶子）完成添加且网关返回有效 `serverId`
- **THEN** 该 eventId 的本地 usage count MUST 增加 1 并写入 SharedPreferences

#### Scenario: Failed add does not increment

- **WHEN** 添加失败或用户在 number Sheet 取消
- **THEN** usage count MUST NOT 变化

#### Scenario: Global device storage without baby isolation

- **WHEN** 用户切换宝宝或 deviceNo 变化
- **THEN** usage counts MUST 仍使用本机全局同一份存储（MUST NOT 按 deviceNo 分桶）

### Requirement: Sort bottom button row by subtree usage score

The home button-mode horizontal grid SHALL order root entries by descending subtree usage score with stable tie-breaking. 底部横条根按钮 MUST 按 **子树用量总分**（自身 count + 所有后代 count 之和）**降序**排列；总分相同 MUST 保持目录 API 原序（稳定排序）；count 为 0 的项 MUST 排在有 usage 的项之后。

#### Scenario: Folder ranked by child usage

- **WHEN** 文件夹「喂养」下子叶「母乳」usage 高于另一根按钮「换尿布」
- **THEN** 横条上「喂养」 MUST 排在「换尿布」之前

#### Scenario: Flat catalog uses own count

- **WHEN** 目录为扁平 legacy（无层级）
- **THEN** 各按钮 MUST 按各自 eventId 的 usage count 降序排列

### Requirement: Sort picker children by usage at each level

The event catalog picker sheet SHALL sort sibling items at every navigation level using the same subtree usage scoring rules. 打开父级文件夹后，Picker 内 **同级子项** MUST 使用与底部横条相同的子树评分规则降序排列；进入更深层级时 MUST 对该层 `childrenOf` 结果独立排序。

#### Scenario: Picker lists sorted children

- **WHEN** 用户点击横条上的文件夹并打开 Picker
- **THEN** 当前层子项列表 MUST 按 usage 降序展示，而非仅 API 序

### Requirement: Re-sort only on HomeScreen initState

The client MUST apply usage-based ordering when HomeScreen initializes and MUST NOT re-sort the button row during the same HomeScreen lifecycle after new increments. 排序 MUST **仅在** `HomeScreen.initState` 加载 counts 并计算顺序；同一会话内后续成功添加 MUST 只更新 prefs、**不得** 即时重排底部横条；从其它路由 pop 回主页且 Home 未重建时 MUST NOT 触发额外重排。

#### Scenario: No in-session resort after add

- **WHEN** 用户停留在主页并成功添加多次
- **THEN** 底部按钮顺序 MUST 与进入主页时一致，直至 HomeScreen 被销毁并再次 initState

#### Scenario: Resort on next home init

- **WHEN** 用户杀进程重启或路由重建导致 HomeScreen 再次 initState
- **THEN** 系统 MUST 从 prefs 加载最新 counts 并应用新的按钮顺序

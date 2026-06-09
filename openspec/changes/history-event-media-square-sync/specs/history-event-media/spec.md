## ADDED Requirements

### Requirement: 历史编辑 Sheet MUST 支持多媒体附件

The history edit sheet SHALL allow attaching up to nine images OR one video for every history event type (not feeding-only). Media selection MUST use the existing UCG compose entry (`showUcgComposeEntrySheet` → `UcgAlbumPickerScreen`) via a "+" control to the right of the remark input.

历史编辑 Sheet 必须为**全部**历史事件类型（非仅喂养）提供多媒体附件能力：最多 **9 张图片**或 **1 条视频**（互斥）。备注输入框右侧 MUST 提供「+」按钮，唤起既有 UCG 相册选择器（`showUcgComposeEntrySheet` / `UcgAlbumPickerScreen`）。

#### Scenario: 添加图片

- **WHEN** 用户点击备注右侧「+」且当前无视频、图片少于 9 张
- **THEN** 客户端 MUST 打开 UCG 相册选择器，选中后 MUST 将缩略图追加到媒体列表

#### Scenario: 图片与视频互斥

- **WHEN** 用户已选 1 条视频
- **THEN** 客户端 MUST NOT 允许再添加图片，且相册选择器 MUST 禁用图片或提示互斥

#### Scenario: 已达 9 张上限

- **WHEN** 用户已选 9 张图片
- **THEN** 「+」按钮 MUST 禁用或点击后 MUST 提示已达上限

### Requirement: 媒体 MUST 以横向条带展示

The client SHALL render attached media in a horizontal scroll strip below the remark field, NOT in a nine-grid layout. Each cell MUST show delete affordance at top-right and MUST support drag reorder consistent with `UcgComposeImageGrid` ordering behavior.

客户端 MUST 在备注输入框**下方**以**横向可滚动条带**展示媒体（**不得**使用九宫格）。每个缩略图右上角 MUST 提供删除；用户 MUST 可通过拖拽调整顺序，排序逻辑与 `UcgComposeImageGrid` 等价。

#### Scenario: 横向条带展示

- **WHEN** 用户已附加至少 1 个媒体项
- **THEN** Sheet MUST 在备注下方展示横向 `ListView` 缩略图条带，且 MUST NOT 渲染九宫格布局

#### Scenario: 删除单个媒体

- **WHEN** 用户点击某缩略图右上角删除
- **THEN** 该媒体 MUST 从编辑态列表移除且界面立即更新

#### Scenario: 拖拽重排

- **WHEN** 用户长按并拖拽某缩略图到新位置
- **THEN** 媒体顺序 MUST 更新且保存时 MUST 按新顺序提交

### Requirement: pending 记录不得编辑媒体

The client MUST NOT allow media pick, delete, or reorder on `pending:*` history records, consistent with read-only pending rules in `home-history-edit-sheet`.

对 `pending:*` 乐观记录，客户端 MUST NOT 提供媒体添加、删除或排序（与历史编辑 Sheet 只读 pending 规则一致）。

#### Scenario: 打开 pending 行

- **WHEN** 用户打开 id 为 `pending:*` 的历史编辑 Sheet
- **THEN** 客户端 MUST NOT 展示可用的「+」或媒体编辑控件

## ADDED Requirements

### Requirement: 转写条挤压历史区

The system SHALL render live partial transcription in a dedicated strip between the history list and the bottom input panel, reducing the history Expanded height. 当语音模式存在非空转写预览（`_partial`）且尚未被服务端回复覆盖时，系统必须在**历史列表与底部固定输入区之间**展示转写条；该转写条高度必须占用纵向空间，使历史 `Expanded` 区域相应变矮（历史内容视觉上被向上推）。

#### Scenario: 按住说话 partial 增长

- **WHEN** 用户处于语音模式且 `_partial` 随识别更新变长
- **THEN** 转写条高度必须随内容增加（直至达到设计上限），且历史列表可视高度必须减小

#### Scenario: 回复到达后移除转写条

- **WHEN** `sendCommand` 返回并写入 `_chatReply`
- **THEN** 转写条必须隐藏，历史区恢复不含转写条的高度分配

### Requirement: 转写全文展示与上限

The system MUST show multi-line partial text without the 3-line caption slot limit, subject to a maximum height cap. 转写条内必须多行展示 `_partial` 全文意图（不得仅用底栏 3 行省略替代）；必须设置最大高度上限（如屏高 30%），超出部分必须可滚动阅读或等价方式访问完整文本。

#### Scenario: 中等长度 partial 完整可见

- **WHEN** `_partial` 长度在上限以内
- **THEN** 用户无需滚动即可在转写条内看到全部当前转写

#### Scenario: 超长 partial 可滚动

- **WHEN** `_partial` 高度超过转写条上限
- **THEN** 转写条必须提供垂直滚动以查看完整内容

### Requirement: 底栏不遮挡语音球

The partial strip MUST NOT be placed over the voice orb or within the fixed bottom input gesture region. 实时转写不得绘制在底部约 220px 输入区内的语音球上方；底栏该区域仅用于按住说话、滑出取消及辅助指示（响度柱等）。

#### Scenario: 转写与语音球分离

- **WHEN** 转写条可见且用户查看底部语音球
- **THEN** 转写条必须位于历史区下方、底栏 Divider 上方，不得与 132px 语音圆重叠

### Requirement: 与底栏服务端回复分工

The system SHALL keep server reply in the bottom caption slot and existing expand-via-bottom-sheet behavior. 服务端回复必须仍在底栏 `HomeInputCaption` 展示；长回复的 BottomSheet 展开行为保持不变；转写条与底栏回复不得同时展示同一 `_partial` 文案。

#### Scenario: 有 partial 时底栏不重复 partial

- **WHEN** 转写条正在展示 `_partial`
- **THEN** 底栏固定字幕槽不得再显示相同 partial 文本

## MODIFIED Requirements

### Requirement: Remark area SHALL collapse until edit is requested

On the unified create sheet and the history **edit** sheet, the remark area MUST default to a collapsed row: when remark text is non-empty, show `{备注信息}` plus an underlined「编辑备注」label and an edit icon; when remark text is empty, show **only**「编辑备注」with the edit affordance（MUST NOT show placeholder copy such as「暂无备注」）, and that empty-state edit affordance MUST be **horizontally centered** within the collapsed row. When remark text is non-empty, the row MUST keep remark body on the start side and the edit affordance on the end side（MUST NOT center the whole non-empty row）. Activating「编辑备注」MUST expand the existing remark `TextField` (or equivalent). Candidate remark chips MUST remain visible regardless of collapsed/expanded state. create 与编辑 sheet 备注区 MUST 默认折叠；空备注 MUST 仅显示「编辑备注」且 MUST 横向居中；有备注 MUST NOT 整行居中。

#### Scenario: Empty collapsed row centered

- **WHEN** create 或编辑 sheet 打开且备注为空且未展开输入
- **THEN** 备注折叠行 MUST 仅展示「编辑备注」与编辑入口，MUST NOT 展示「暂无备注」类占位
- **AND** 「编辑备注」与编辑入口 MUST 在该行内横向居中

#### Scenario: Non-empty collapsed row

- **WHEN** 备注非空且未展开输入
- **THEN** 折叠行 MUST 同时展示备注正文与「编辑备注」编辑入口
- **AND** 正文 MUST 靠起始侧、编辑入口 MUST 靠末侧（MUST NOT 整行居中）

#### Scenario: Expand to field

- **WHEN** 用户点按「编辑备注」
- **THEN** 客户端 MUST 展开备注输入框供编辑

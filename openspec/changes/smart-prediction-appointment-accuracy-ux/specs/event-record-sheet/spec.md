## MODIFIED Requirements

### Requirement: Prediction confirm-add dialog SHALL remain for non-quantity add only

When the prediction page invokes add on a direct leaf with `confirmDirectLeafBeforeAdd` and intent is `add` and type is `time` or `one`, the client MUST open the unified create/edit-style record sheet (time and remark affordances) and MUST NOT show the「确认添加」glass confirm dialog as the gate that immediately submits a now occurrence. When intent is `supplement`, the client MUST continue to open the unified sheet and MUST NOT show that confirm dialog. 预测页直点叶子在普通新增 `time|one` 时 MUST 直接打开统一记录 sheet，MUST NOT 再以「确认添加」即时提交 now；补充路径仍直接 sheet 且 MUST NOT 先弹确认框。

#### Scenario: One add opens sheet

- **WHEN** 用户在预测卡对 `eventType=one`（或 `time`）叶子发起普通新增
- **THEN** 客户端 MUST 打开统一记录 sheet，MUST NOT 先弹「确认添加」后直接 now 提交

#### Scenario: Supplement still sheet without confirm

- **WHEN** 用户对 `time|one` 走补充意图
- **THEN** 客户端 MUST 直接打开统一 Sheet 且 MUST NOT 先弹「确认添加」

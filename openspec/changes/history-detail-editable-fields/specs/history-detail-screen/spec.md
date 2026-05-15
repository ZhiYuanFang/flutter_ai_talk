## ADDED Requirements

### Requirement: 历史详情删除当前事件

The client SHALL 在历史详情页提供删除当前条目的操作，并在用户确认后调用网关删除接口；删除成功 MUST 关闭详情页并返回结果以便列表刷新。删除失败 MUST 向用户展示可读错误信息且保留当前页。

#### Scenario: 用户确认并删除成功

- **WHEN** 用户点击删除并确认，且网关返回成功  
- **THEN** 客户端 MUST 关闭详情页并返回「已变更」类结果供首页等刷新列表

#### Scenario: 用户取消删除

- **WHEN** 用户在确认对话框选择取消  
- **THEN** 客户端 MUST 不发起删除请求并保持当前详情状态不变

### Requirement: 事件名与动作只读、备注可编辑

The client SHALL 在详情页将事件名与动作类主信息设为只读展示；用户 MUST 能够通过独立输入编辑**备注**（`remark`）。客户端 MUST NOT 将事件名或可编辑「动作」字段与更新请求中的只读语义混用（更新请求中事件名 MUST 与原始记录一致或仅由服务端只读校验）。

#### Scenario: 保存备注修改

- **WHEN** 用户仅修改备注并保存  
- **THEN** 更新请求 MUST 携带新的 `remark`，且事件名 MUST 与进入详情时的记录一致

### Requirement: eventNumber 为 0 时可编辑开始与结束时间

The client SHALL 当 `eventNumber == 0` 时提供开始时间与结束时间的编辑能力（结束时间未设置时允许为空或与网关「0」语义一致）；保存时 MUST 在请求体中提交 `startTime` / `endTime`，且二者 MUST 为 **Unix 秒级整型时间戳**（非毫秒、非日期时间字符串）；未设置结束时 `endTime` MUST 为 `0`。

#### Scenario: 计时类记录修改起止时间

- **WHEN** 当前记录 `eventNumber == 0` 且用户修改了开始或结束时间并保存  
- **THEN** 客户端 MUST 提交对应时间字段，且不得要求用户修改事件名或动作只读区

### Requirement: eventNumber 为 1 时仅可编辑结束时间

The client SHALL 当 `eventNumber == 1` 时仅展示结束时间的编辑控件，不得展示可编辑的开始时间控件。服务端 MUST 在用户修改结束时间后将开始时间自动调整为与结束时间一致；客户端提交时 `startTime` 与 `endTime` MUST 均为 **Unix 秒级整型时间戳**（通常同为所选结束时刻的秒值）。

#### Scenario: 单次事件仅改结束时间

- **WHEN** `eventNumber == 1` 且用户修改结束时间并保存  
- **THEN** 客户端 MUST 仅提交结束时间相关字段（开始时间是否由客户端重复发送由网关约定；若网关允许省略开始时间，客户端 SHOULD 不发送误导性开始时间）

### Requirement: eventNumber 大于 1 时可编辑结束时间与用量

The client SHALL 当 `eventNumber > 1` 时提供结束时间编辑（与上条相同的后台开始时间同步语义）以及**用量**编辑（至少包含次数类数值，对应 payload 中 `eventNumber` 或与网关约定的用量字段）。保存时 MUST 提交用量相关字段与结束时间；`startTime` 与 `endTime` MUST 为 **Unix 秒级整型时间戳**。

#### Scenario: 多次计数类记录修改用量与结束时间

- **WHEN** `eventNumber > 1` 且用户修改用量或结束时间并保存  
- **THEN** 更新请求 MUST 携带新的用量数值与结束时间，且事件名与只读动作区未被用户修改

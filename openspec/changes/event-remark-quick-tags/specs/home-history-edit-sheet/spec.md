## MODIFIED Requirements

### Requirement: 事件名与备注可编辑

The client SHALL allow editing **remark** (`remark`) on the history edit sheet. When local quick-tag cache exists for the record's eventId, the client SHALL show remark quick-select tags below the remark field per capability **event-remark-quick-tags**. On successful save with a non-empty remark, the client SHALL update the per-eventId remark cache.

历史编辑 Sheet MUST 允许编辑备注；当该 eventId 有本地缓存时 MUST 在备注框下方展示快捷标签；保存成功且 remark 非空时 MUST 更新缓存。

#### Scenario: 编辑页展示快捷标签

- **WHEN** 用户打开历史编辑 Sheet 且该记录 eventId 有本地备注缓存
- **THEN** 备注输入框下方 MUST 展示快捷标签，点击 MUST 替换输入框全文

#### Scenario: 编辑保存更新缓存

- **WHEN** 用户保存编辑且 remark 去空白后非空
- **THEN** 客户端 MUST 更新该 eventId 的备注缓存

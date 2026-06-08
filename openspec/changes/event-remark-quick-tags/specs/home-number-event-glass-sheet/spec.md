## MODIFIED Requirements

### Requirement: number 二级页数量与 remark

The client SHALL provide a secondary sheet for `number` events with datetime selection, quantity picker from **5 to 500 inclusive in steps of 5** without free-text numeric entry, and optional remark editing. Below the remark field, when local quick-tag cache exists for the eventId, the client SHALL show remark quick-select tags per capability **event-remark-quick-tags**. On confirm with a non-empty remark, the client SHALL update the per-eventId remark cache. **`time`** 与 **`one`** 创建时 `remark` 必须为 **空字符串**，且不得提供 remark 编辑 UI。

#### Scenario: number 二级页含快捷标签

- **WHEN** 用户打开 `eventType` 为 `number` 的事件二级页且该 eventId 有本地备注缓存
- **THEN** 备注输入框下方 MUST 展示快捷标签；确认非空 remark 后 MUST 更新缓存

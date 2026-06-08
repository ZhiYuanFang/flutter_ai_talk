## ADDED Requirements

### Requirement: Event remark quick tags SHALL cache recent remarks per eventId locally

The client SHALL persist up to three most recently used non-empty remark strings per catalog **eventId** in local storage (SharedPreferences). Duplicate remarks MUST move to the front (LRU). Empty or whitespace-only remarks MUST NOT be stored. Storage keys MUST be scoped by eventId only; different eventIds MUST NOT share the same cache. Device/baby isolation is NOT required.

客户端 MUST 按 **eventId** 在本地缓存最近 **3** 条非空备注（LRU、去重）；不同 eventId 的缓存 MUST 互不影响。

#### Scenario: 确认 number 事件后写入缓存
- **WHEN** 用户在 number 二级页确认记录且 remark 去空白后非空
- **THEN** 客户端 MUST 将该 remark 写入该 eventId 的本地缓存（去重后保留最多 3 条）

#### Scenario: 编辑保存后写入缓存
- **WHEN** 用户在历史编辑 Sheet 保存成功且 remark 去空白后非空
- **THEN** 客户端 MUST 将该 remark 写入该记录 eventId 的本地缓存

#### Scenario: 空备注不写入
- **WHEN** 用户确认或保存时 remark 为空或仅空白
- **THEN** 客户端 MUST NOT 更新该 eventId 的备注缓存

### Requirement: Remark input sheets SHALL show quick-select tags below the remark field

When local cache for the current eventId contains one or more remarks, the client SHALL render quick-select tags directly below the remark TextField on the number event glass sheet and the history edit sheet. Tags MUST use `Wrap` with 3px horizontal and vertical spacing, auto line wrap, **white** border and text, and theme primary fill at 0.3 opacity. Tag text MUST NOT be truncated. Tapping a tag MUST replace the entire remark field content with the tag text.

当某 eventId 存在本地备注缓存时，number 二级页与历史编辑页 MUST 在备注输入框下方展示快捷标签；点击标签 MUST 替换输入框全文。

#### Scenario: 展示快捷标签
- **WHEN** 用户打开 number 二级页或历史编辑页且该 eventId 缓存含 1–3 条备注
- **THEN** 备注输入框下方 MUST 以 Wrap 展示对应标签，间距 3px，**白色**边框与文字、主题色 0.3 透明浅底填充

#### Scenario: 点击标签替换全文
- **WHEN** 用户点击某快捷标签
- **THEN** 备注输入框内容 MUST 被替换为该标签全文（不得追加）

#### Scenario: 无缓存不占位
- **WHEN** 该 eventId 本地无备注缓存
- **THEN** 客户端 MUST NOT 展示标签区域占位

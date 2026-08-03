## ADDED Requirements

### Requirement: Companion answers MUST NOT show thumbs feedback controls

After a successful companion assistant answer, the client MUST NOT render thumbs-up or thumbs-down feedback controls, and MUST NOT call the clinic feedback API from the companion UI. 陪伴成功回答后 **不得** 展示赞/踩，**不得** 从陪伴 UI 调用 clinic feedback 接口。

#### Scenario: 答后无赞踩

- **WHEN** 助手轮次 `answer_done` 且 answer 非空
- **THEN** 该助手行 MUST NOT 渲染赞或踩按钮

### Requirement: Home tip panel MUST NOT show thumbs feedback controls

The home tip panel MUST NOT render thumbs-up or thumbs-down controls and MUST NOT submit tip feedback from that panel. 首页小贴士面板 **不得** 展示赞/踩，**不得** 从该面板提交 tip feedback。

#### Scenario: 小贴士无赞踩

- **WHEN** tip 处于 `done` 且有可展示内容
- **THEN** 面板 MUST NOT 渲染赞或踩按钮
- **AND** 关闭按钮与整卡进陪伴行为 MAY 保持不变

### Requirement: Companion MUST hide thinking when answer is present

When an assistant chat item has a non-empty `answer`, the client MUST NOT render the thinking block for that item, including items restored from local cache or `session_sync`. While streaming with non-empty thinking and still-empty answer, the client MAY render thinking. 助手项存在非空 `answer` 时 **不得** 渲染 thinking（含历史）；仅 thinking 流式且尚无 answer 时 MAY 展示 thinking。

#### Scenario: 答后不画 thinking

- **WHEN** 助手项 `answer` 非空且 `thinking` 非空
- **THEN** UI MUST NOT 构建 thinking 组件

#### Scenario: 历史 hydrate 亦不画

- **WHEN** 从本地 store 恢复的轮次同时含 thinking 与 answer
- **THEN** UI MUST 仅展示 answer（及弱提示等），MUST NOT 展示 thinking

#### Scenario: 流式仅 thinking 仍可见

- **WHEN** 进行中轮次已有 thinking 且 answer 仍为空
- **THEN** UI MAY 展示 thinking 流式内容

## ADDED Requirements

### Requirement: Companion completed assistant answer is selectable

The companion (树洞) chat UI SHALL allow the user to select and copy text from a completed assistant answer bubble, including tip-injected assistant content, via the platform text selection affordance.

树洞中已完成的助手答复（含 tip 注入气泡）必须支持系统长按选区与复制；流式进行中可不要求可选，流式结束后必须可选。首页 tip 面板不得因本需求改为可选。

#### Scenario: Long-press copy on completed answer

- **WHEN** 用户在树洞中查看一条已完成的助手答复（非流式）并长按正文
- **THEN** 松手后选区仍保持，并可通过系统菜单复制到剪贴板

#### Scenario: Tip-injected answer is selectable

- **WHEN** 树洞中展示 tip 注入的助手气泡且内容已完成展示
- **THEN** 该气泡正文与普通助手答复一样可选可复制

#### Scenario: Streaming answer becomes selectable after done

- **WHEN** 助手答复仍在流式输出
- **THEN** 客户端可不提供选区
- **WHEN** 该答复流式结束并完成渲染
- **THEN** 用户可以选中并复制该答复正文

#### Scenario: Home tip panel stays non-selectable

- **WHEN** 用户在首页 tip 面板上操作
- **THEN** tip 正文保持不可选（避免与 tip 手势冲突），行为不因本变更改变

### Requirement: Companion user bubble text is selectable

The companion chat UI SHALL allow the user to select and copy text from a user message bubble. When companion consent is granted, the UI MUST provide a non-text-gesture control (e.g. icon button) that fills the compose input with that question text.

用户气泡正文必须可选可复制；在已同意陪伴的前提下，必须提供不依赖点击正文的控件（如「填入输入框」图标）将该问题填回输入框，以免与选区手势冲突。

#### Scenario: Long-press copy on user bubble

- **WHEN** 用户长按树洞中的用户气泡正文
- **THEN** 用户可以选中片段，松手后选区仍保持，并可通过系统菜单复制

#### Scenario: Icon fills input when consented

- **WHEN** 用户已同意陪伴，并点击用户气泡旁的「填入输入框」控件
- **THEN** 输入框被填入该气泡的完整问题文本

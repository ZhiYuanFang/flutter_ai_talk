## ADDED Requirements

### Requirement: Companion conversation bubbles remain visible

The companion chat UI SHALL render user and assistant message bubbles normally. The client MUST NOT disable clipping on glass panels that use `BackdropFilter` in a way that breaks list layout or painting (e.g. `Clip.none` around `BackdropFilter`).

树洞消息列表必须正常展示用户与助手气泡；不得对带 `BackdropFilter` 的玻璃使用会导致列表布局/绘制异常的裁剪关闭（如 `Clip.none`）。

#### Scenario: Bubbles visible after open companion

- **WHEN** 用户打开树洞且会话中有用户与助手消息
- **THEN** 两类气泡均可见且可滚动浏览

### Requirement: Companion assistant long-press shows copy action above content

The companion chat UI SHALL, on a long-press of a completed assistant answer bubble (including tip-injected assistant content), present a **「复制」** control above the pressed/selected region. Activating **「复制」** MUST write copyable text to the system clipboard. When a reliable selected fragment is unavailable, the client MUST fall back to copying the full assistant answer body.

用户长按已完成助手答复（含 tip 注入）时，必须在内容上方展示「复制」；点击后必须写入剪贴板。若无法可靠取得选中片段，则必须回退为复制该条助手完整正文。

#### Scenario: Long-press shows copy button

- **WHEN** 用户长按一条已完成的助手答复气泡
- **THEN** 在内容上方出现「复制」控件

#### Scenario: Copy writes clipboard

- **WHEN** 用户点击该「复制」控件
- **THEN** 系统剪贴板含选中片段或该条完整助手正文，并关闭该控件（或等价不再遮挡）

#### Scenario: Home tip stays non-selectable

- **WHEN** 用户在首页 tip 面板上操作
- **THEN** tip 正文保持不可选，行为不因本变更改变

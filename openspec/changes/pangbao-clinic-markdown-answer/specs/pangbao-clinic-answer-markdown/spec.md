## ADDED Requirements

### Requirement: Clinic answer SHALL render Markdown after streaming completes

The Pangbao clinic screen (`PangbaoAiScreen`) MUST render assistant `answer` text as formatted Markdown when the answer is complete. During in-flight `answer_delta` streaming for the active assistant turn, the client MUST display the accumulated answer as plain `Text` (raw Markdown characters MAY remain visible). After `answer_done`, and for all answers restored via `session_sync`, the client MUST render the same string using the clinic Markdown answer widget.

胖宝诊疗页必须在助手答案完成后将 `answer` 渲染为 Markdown 格式化视图。当前轮次 `answer_delta` 流式进行中 MUST 以纯文本 `Text` 展示累积内容（允许用户看到原始 Markdown 字符）。`answer_done` 之后以及 `session_sync` 恢复的历史答案 MUST 使用诊疗 Markdown 答案组件渲染同一字符串。

#### Scenario: 流式阶段展示纯文本

- **WHEN** 用户已发送问题且客户端正在接收 `answer_delta`、`_busy` 为 true
- **THEN** 答案气泡 MUST 以纯文本展示当前累积的 `answer` 字符串
- **AND** MUST NOT 在流式完成前将答案解析为 Markdown 结构化视图

#### Scenario: 流式完成后切换 Markdown

- **WHEN** 客户端收到 `answer_done` 且 `answer` 非空
- **THEN** 该轮答案气泡 MUST 以 Markdown 格式化视图展示完整 `answer`
- **AND** MUST NOT 继续以流式纯文本模式展示该轮答案

#### Scenario: 历史同步与完成态一致

- **WHEN** 客户端通过 `session_sync` 恢复已完成轮次的 `answer`
- **THEN** 每条历史答案 MUST 与 `answer_done` 后答案使用相同的 Markdown 渲染规则

### Requirement: Clinic answer Markdown SHALL support DeepSeek-common subset

The clinic Markdown renderer MUST correctly display DeepSeek-typical constructs: headings (`#` through `###`), bold (`**text**`), horizontal rules (a line containing only `---`), paragraph breaks, unordered lists (`-`, `*`, or `+`), and ordered lists (`1.` style). The renderer SHOULD support italic, inline code, and block quotes when the underlying Markdown package allows. Constructs outside this subset (tables, images, fenced code blocks) MUST degrade to readable text without layout failure.

诊疗 Markdown 渲染器 MUST 正确展示 DeepSeek 常见结构：标题（`#` 至 `###`）、粗体（`**文本**`）、独占一行的水平分隔线 `---`、段落换行、无序列表（`-`/`*`/`+`）与有序列表（`1.` 样式）。在底层 Markdown 包能力允许时 SHOULD 支持斜体、行内代码与引用块。超出子集的语法（表格、图片、围栏代码块）MUST 降级为可读文本且不得引发布局异常。

#### Scenario: 三级标题与粗体

- **WHEN** 已完成答案包含行 `### 建议` 与行内 `**及时就医**`
- **THEN** 用户 MUST 看到「建议」以强调标题样式展示（不显示 `###` 前缀）
- **AND** 「及时就医」MUST 以粗体展示（不显示 `**` 标记）

#### Scenario: 无序列表

- **WHEN** 已完成答案包含 Markdown 无序列表项 `- 观察体温`
- **THEN** 用户 MUST 看到带项目符号或等价列表缩进的列表项「观察体温」

#### Scenario: 水平分隔线

- **WHEN** 已完成答案包含独占一行的 `---`
- **THEN** 用户 MUST 看到水平分隔线而非三字面值 `---`

#### Scenario: 非支持语法降级

- **WHEN** 已完成答案包含 Markdown 表格或图片语法
- **THEN** 页面 MUST 保持可滚动且答案气泡 MUST NOT 抛出布局异常
- **AND** 用户 MUST 仍能阅读降级后的文本内容

### Requirement: Clinic thinking and disclaimer SHALL remain plain text

The client MUST NOT apply Markdown rendering to assistant `thinking` content, user question bubbles, or the fixed medical disclaimer line below each completed answer.

客户端 MUST NOT 对助手 `thinking` 内容、用户提问气泡以及每条已完成答案下方的固定医疗免责声明行应用 Markdown 渲染。

#### Scenario: 思考块保持纯文本

- **WHEN** 助手 `thinking` 字符串包含 `###` 或 `**` 等 Markdown 标记
- **THEN** 思考块 MUST 按纯文本原样或等效纯文本展示
- **AND** MUST NOT 解析为标题或粗体

#### Scenario: 免责声明不受 Markdown 影响

- **WHEN** 答案已完成并显示免责声明「本回答仅供参考，不能替代医生诊断」
- **THEN** 免责声明 MUST 以固定小号灰色纯文本展示
- **AND** MUST NOT 经 Markdown 解析器处理

### Requirement: Clinic answer links SHALL NOT be tappable in v1

When answer Markdown contains link syntax `[label](url)`, the client MUST display the visible link label text only and MUST NOT open external URLs or invoke `url_launcher` for clinic answers.

当答案 Markdown 含 `[文字](url)` 链接语法时，客户端 MUST 仅展示可见链接文字，且 MUST NOT 为诊疗答案打开外链或调用 `url_launcher`。

#### Scenario: 链接仅展示文字

- **WHEN** 已完成答案包含 `[参考说明](https://example.com)`
- **THEN** 用户 MUST 看到文字「参考说明」
- **AND** 点击该文字 MUST NOT 打开浏览器或应用外页面

### Requirement: Clinic answer Markdown styles SHALL follow app theme

Markdown heading, body, bold, list, and divider styles MUST be derived from the active `Theme` / `ColorScheme` so that light and dark shells remain readable inside the existing answer bubble container.

Markdown 标题、正文、粗体、列表与分隔线样式 MUST 派生自当前 `Theme` / `ColorScheme`，以确保在现有答案气泡容器内深浅色主题均可读。

#### Scenario: 深色主题下答案可读

- **WHEN** 用户处于深色主题且答案含标题与正文
- **THEN** 格式化文本颜色 MUST 与 `ColorScheme.onSurface` 或其派生色一致且对比度可读
- **AND** MUST NOT 硬编码仅适用于浅色主题的前景色导致不可读

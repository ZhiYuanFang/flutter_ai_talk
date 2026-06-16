## Why

胖宝诊疗（`PangbaoAiScreen`）当前以纯 `Text` 展示 DeepSeek 返回的 `answer` 字符串，Markdown 标记（如 `###`、`**`、`-` 列表、`---`）会原样显示，结构化建议难以阅读。DeepSeek 诊疗回答普遍采用 Markdown 分节与列表，需在流式完成后将答案渲染为格式化视图，并与 `session_sync` 历史轮次保持一致。

## What Changes

- 新增客户端 Markdown 答案渲染组件，封装 DeepSeek 常见子集（标题、粗体、列表、分隔线、段落；斜体/行内代码尽力支持）。
- `answer_delta` 流式阶段继续以纯文本展示原始字符串（允许可见 Markdown 字符）；`answer_done` 及 `session_sync` 历史答案 MUST 渲染为格式化 Markdown 视图。
- 思考块（`thinking`）、用户气泡、固定免责声明保持纯文本，不解析 Markdown。
- v1 链接语法 `[text](url)` 仅展示可见文字，不得打开外链。
- 新增 Flutter Markdown 渲染依赖（具体包名见 design.md）；**不修改** Clinic WS 协议与帧结构。

## Capabilities

### New Capabilities

- `pangbao-clinic-answer-markdown`：胖宝诊疗助手答案的 Markdown 子集渲染、流式/完成态展示策略、历史同步一致性及降级规则。

### Modified Capabilities

（无。`openspec/specs/` 基线尚无胖宝诊疗独立 capability，本变更为新增能力。）

## Impact

- **Flutter**：`app/lib/ui/pangbao_ai_screen.dart`（答案气泡展示逻辑）；新增 `app/lib/ui/widgets/` 或 `app/lib/ui/pangbao/` 下 Markdown 答案组件。
- **依赖**：`app/pubspec.yaml` 新增 Markdown 渲染包。
- **不在范围**：后端 prompt 调整、WS 帧字段变更、思考块 Markdown、自动化测试文件、链接点击与外链合规流程。

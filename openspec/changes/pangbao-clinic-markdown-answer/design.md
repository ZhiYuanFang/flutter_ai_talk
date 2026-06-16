## Context

- **现状**：`PangbaoAiScreen` 通过 `ClinicWsClient` 接收 `thinking_delta` / `answer_delta` / `answer_done` / `session_sync` 帧；助手 `answer` 以 `Text(item.answer ?? '')` 原样展示，Markdown 标记对用户可见。
- **约束**：WS 协议不变（`answer` 仍为单一字符串）；用户已接受「流式阶段纯文本、完成后格式化」；思考块与免责声明保持纯文本。
- **DeepSeek 输出特征**：诊疗类回答常见 `##`/`###` 标题、`**粗体**`、`-`/`1.` 列表、`---` 分隔线、空行分段；偶见 `*斜体*`、`` `行内代码` ``；链接与表格较少。
- **平台**：Flutter 三端（Android / iOS / Web）；当前 `pubspec.yaml` 无 Markdown 渲染依赖。

## Goals / Non-Goals

**Goals:**

- 流式 `answer_delta` 阶段以 `Text` 展示累积字符串（可含裸 Markdown 字符）。
- `answer_done` 后与 `session_sync` 历史答案以 Markdown 格式化渲染，样式接入 `Theme`。
- 覆盖 DeepSeek 高概率子集：标题（`#`–`###`）、粗体、无序/有序列表（一层嵌套）、水平线 `---`、段落；尽力支持斜体与行内代码。
- 未识别或高级语法（表格、图片、围栏代码块）降级为可读纯文本，不得引发布局异常。
- v1 链接 `[text](url)` 仅显示链接文字，不可点击。

**Non-Goals:**

- 流式过程中实时 Markdown 解析。
- 思考块 Markdown、用户气泡富文本。
- 修改后端 prompt、Clinic WS 帧结构或 `go_ai_talk` 诊疗服务。
- 外链打开、`url_launcher` 集成、链接白名单（后续迭代）。
- 新增 `test/**` 自动化测试文件。

## Decisions

### 1. 流式策略：完成后切换渲染器

**Decision**：定义 `isStreamingAnswer = (item == _activeAssistant && _busy && answer 非空)`；为 true 时用 `Text`，否则用 Markdown 组件。

**Why**：避免流式半成品 Markdown 解析闪烁与性能问题；与用户确认的「打完再格式化」一致。

**Alternatives**：全程 Markdown 解析 — 半成品语法体验差；流式仅解析 `**` — 两套逻辑，收益有限。

### 2. 使用 Markdown 库而非自研解析器

**Decision**：在 `pubspec.yaml` 引入 `markdown_widget`（或实现期评估等价的活跃 Markdown 包，须支持 Web）。封装为 `ClinicAnswerBody`（或 `PangbaoClinicMarkdownAnswer`）单一入口 widget。

**Why**：列表与标题的边界情况多，自研维护成本高；完成后一次性 parse，无流式性能负担。

**Alternatives**：自研 `###`/`**`/`---` 子集 — 无法覆盖 DeepSeek 常见列表；`gpt_markdown` — 面向流式，本场景非必需。

### 3. 支持语法分层（Tier）

**Decision**：

| Tier | 语法 | v1 要求 |
|------|------|---------|
| 1 | `#`–`###` 标题、`**bold**`、`---`、段落 | MUST 正确渲染 |
| 2 | `-`/`*`/`+` 无序列表、`1.` 有序列表 | MUST 正确渲染 |
| 3 | `*italic*`、`` `code` ``、`>` 引用 | SHOULD 渲染；失败则降级为纯文本 |
| 4 | 链接、表格、图片、围栏代码块 | 降级；链接仅显示文字 |

**Why**：与探索阶段 DeepSeek 兼容性结论对齐；Tier 4 规避医疗 App 外链合规风险。

### 4. 样式映射

**Decision**：Markdown 样式表从 `Theme.of(context)` 派生：

- 标题：`titleSmall` / `titleMedium`（`#` 最深字号阶梯不超过 `titleMedium`）
- 正文：`bodyMedium`，`height: 1.45`
- 粗体：`FontWeight.w600`
- 分隔线：`Divider` 色 `outlineVariant`，上下 `8–12` 逻辑像素间距
- 列表：左侧缩进与聊天气泡 `padding` 协调，避免溢出圆角容器

**Why**：与现有 `surfaceContainerHighest` 答案气泡、`Ucg` 正文节奏一致。

### 5. 组件边界

**Decision**：

```
PangbaoAiScreen._buildItem
├── user bubble → Text（不变）
├── _ThinkingBlock → Text（不变）
├── answer Container → ClinicAnswerBody(text, streaming: isStreamingAnswer)
└── disclaimer → Text（不变）
```

`ClinicAnswerBody` 置于 `app/lib/ui/widgets/clinic_answer_body.dart`（或 `app/lib/ui/pangbao/` 目录，实现期二选一，以 tasks 为准）。

**Why**：单一复用点，`session_sync` 与 `answer_done` 路径共用。

### 6. 链接不可点击

**Decision**：配置 Markdown 包不注册 `onTapLink`，或将 link 渲染为与正文同色的 `Text` span。

**Why**：v1 避免未审查外链；规格可后续 MODIFIED 增加确认对话框 + `url_launcher`。

## Risks / Trade-offs

- **[Risk] 流式结束瞬间格式跳变** → 已在规格中定义为预期行为；可选 polish：流式时剥行首 `### `（非 v1 必须）。
- **[Risk] Markdown 包 Web 兼容性** → 实现期在 `flutter run -d chrome` 验证；若包不支持 Web 则换 `flutter_markdown_plus` 等等价方案。
- **[Risk] 极长答案 parse 卡顿** → 完成后单次 parse，诊疗回答长度通常可接受；若卡顿再考虑 isolate（非 v1）。
- **[Risk] DeepSeek 输出非标准 Markdown** → Tier 3/4 降级规则 + 手工样例走查（tasks 验证项）。

## Migration Plan

- 纯客户端增量：发版即生效；无数据迁移。
- 回滚：移除 Markdown 依赖并恢复 `Text` 展示即可。
- 历史 `session_sync` 答案若含 Markdown，升级后自动获得格式化展示（向前兼容）。

## Open Questions

- 实现期最终选用 `markdown_widget` 还是 `flutter_markdown_plus`（以 Web 渲染与包体为准）。
- 是否需要在流式阶段隐藏行首 `#` 字符（UX polish，可放 tasks 可选项）。

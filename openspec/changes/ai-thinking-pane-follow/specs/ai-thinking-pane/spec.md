## ADDED Requirements

### Requirement: Scrollable AI thinking body SHALL use shared AiThinkingPane

Whenever the client renders **agent streaming or expandable full thinking text inside a vertically scrollable region**, the client MUST use the shared `AiThinkingPane` widget (or the single public equivalent under `app/lib/ui/widgets/`). Feature modules MUST NOT introduce a parallel scroll-follow implementation for AI thinking bodies. Non-scroll surfaces (e.g. single-line voice subtitles, non-scroll placeholders) are out of scope.

凡以**可纵向滚动区域**展示 agent 流式或展开后的完整思考正文时，客户端 **必须** 使用共享 `AiThinkingPane`（或 `app/lib/ui/widgets/` 下唯一公开等价物）；feature **不得** 再实现平行的思考跟滚。非滚动表面不适用本条。

#### Scenario: 新可滚动思考 UI 必须复用

- **WHEN** 新增或修改某处 UI 以可滚动区域展示 AI 思考正文
- **THEN** 实现 MUST 使用共享 `AiThinkingPane`
- **AND** MUST NOT 在 feature 内新建独立的 ScrollController 跟底逻辑复制品

### Requirement: AiThinkingPane SHALL follow bottom until user scrolls up

While `followLatest` is true, when the thinking `text` grows, the pane MUST scroll so the latest content remains visible (typically `jumpTo(maxScrollExtent)` after layout). When the user scrolls up such that the viewport is farther from the bottom than a small threshold, the pane MUST set `followLatest` to false and MUST show a floating control that scrolls down. Tapping that control MUST set `followLatest` to true and scroll to the bottom. Scrolling back near the bottom by user gesture MUST NOT by itself restore `followLatest`.

`followLatest` 为真时，`text` 增长 **必须** 跟滚使最新内容可见。用户上翻超过离底阈值时 **必须** 暂停跟滚并显示回底控件；点击控件 **必须** 恢复跟滚并滚到底。用户手势自行滑回近底 **不得** 单独恢复 `followLatest`。

#### Scenario: 流式默认跟底

- **WHEN** 思考正文持续追加且用户未上翻
- **THEN** 可视区域 MUST 保持展示最新追加内容

#### Scenario: 上翻暂停并显示回底钮

- **WHEN** 用户将思考区上翻至离底部超过阈值
- **THEN** 后续 `text` 增长 MUST NOT 强制打乱用户当前阅读位置
- **AND** UI MUST 在思考区底部附近展示向下回底控件

#### Scenario: 仅按钮恢复跟滚

- **WHEN** 跟滚已暂停
- **AND** 用户自行滑动使视口接近底部但未点击回底控件
- **THEN** `followLatest` MUST 仍为 false，回底控件 MUST 仍可见
- **WHEN** 用户点击回底控件
- **THEN** 客户端 MUST 滚到底部并恢复自动跟滚，且 MUST 隐藏回底控件

### Requirement: Jump-to-bottom control color SHALL use accent or theme primary

The floating jump-to-bottom control MUST use the caller-supplied feature/accent color when provided; when no accent is supplied, it MUST use `ColorScheme.primary`. The control MUST remain readable (adequate contrast for the icon/label on its fill).

回底控件 **必须** 优先使用调用方传入的功能/强调色；未传入时 **必须** 使用 `ColorScheme.primary`；图标/文案 **必须** 保持可读对比度。

#### Scenario: 传入功能色

- **WHEN** `AiThinkingPane` 收到非空 accent/功能色
- **THEN** 回底控件主色 MUST 为该色（或以其为填充主色）

#### Scenario: 未传功能色

- **WHEN** 未传入 accent/功能色
- **THEN** 回底控件主色 MUST 为当前主题 `ColorScheme.primary`

### Requirement: Feeding analysis and growth trajectory SHALL use AiThinkingPane

The feeding-record analysis workspace and the growth-trajectory workspace MUST render their streaming thinking bodies via `AiThinkingPane` and MUST NOT keep separate private thinking scroll panes that omit follow/pause/jump behavior.

喂养记录分析与成长轨迹工作区的流式思考正文 **必须** 经 `AiThinkingPane` 展示，**不得** 保留缺少跟滚/暂停/回底行为的私有思考滚动条。

#### Scenario: 喂养分析流式跟底

- **WHEN** 用户在喂养记录分析页触发分析且 thinking 流式增长超过限高
- **THEN** 思考区 MUST 跟滚展示最新文案，直至用户上翻暂停

#### Scenario: 成长轨迹流式跟底

- **WHEN** 用户在成长轨迹预测页触发预测且 thinking 流式增长超过限高
- **THEN** 思考区 MUST 与喂养分析同一跟滚/暂停/回底语义

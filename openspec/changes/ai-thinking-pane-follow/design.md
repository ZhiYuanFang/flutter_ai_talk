## Context

- 喂养 / 成长：私有 Stateless 思考 pane，`maxHeight ≈ 0.4 * screen`，无 `ScrollController`，流式 rebuild 停在顶部。
- 诊疗 `_ThinkingBlock`：流式为无界 `Text`；折叠为固定高度尾部 `Align`（规格禁止折叠态用 jumpTo 跟流）；展开为无跟滚的 `SingleChildScrollView`。
- UCG 聊天有 `_followLatest` + 近底阈值，但近底会恢复跟滚；本需求 **禁止** 近底自动恢复，只认按钮。
- 全局强制约定权威入口：`openspec/project.md`（`AGENTS.md` 摘要）。

## Goals / Non-Goals

**Goals:**

- 单一共享组件承载：默认跟底、上翻暂停、回底 FAB、功能色/主题色。
- 喂养、成长、诊疗（流式 + 展开）全部改用该组件。
- `project.md` / `AGENTS.md` 落强制条款，约束后续所有可滚动 AI 思考正文。

**Non-Goals:**

- 不改 thinking SSE / `\r` stage 合并逻辑（`applyThinkingStageDelta`）。
- 不改诊疗「答后不画 thinking」、折叠尾部窗口算法与「点击展开」壳层。
- 不强制横屏语音字幕、纯占位「正在思考…」迁入（非可滚动思考正文）。
- 不新建测试文件。

## Decisions

### 1. 组件 API

```dart
AiThinkingPane({
  required String text,
  TextStyle? style,
  Color? accentColor, // 回底钮；null → ColorScheme.primary
  double maxHeightFactor = 0.4, // 相对屏高；诊疗可传更小或固定 maxHeight
  double? maxHeight, // 若设则优先于 factor
})
```

内部：`ScrollController`、`followLatest`（默认 true）、离底阈值（如 80px，仅用于判定「上翻暂停」，**不**用于自动恢复）。

### 2. 跟滚状态机

| 事件 | 行为 |
|------|------|
| `text` 变化且 `followLatest` | post-frame `jumpTo(maxScrollExtent)` |
| 用户滚动且 `extentBefore` 离底 > 阈值 | `followLatest=false`，显示回底钮 |
| 用户滚动至近底 | **不**改 `followLatest`（钮仍显示直至点击） |
| 点击回底钮 | `followLatest=true`，`jumpTo(max)`，隐藏钮 |
| `text` 变短（`\r` 清阶段） | 若仍 follow 则跟到底；若已暂停保持位置 |

### 3. 回底按钮 UI

- 悬停在 pane **底部内侧**（`Stack` + `Positioned`），不挡过多正文（可半透明圆钮 + `Icons.arrow_downward`）。
- 背景/图标色：`accentColor ?? Theme.of(context).colorScheme.primary`；前景对比用 `onPrimary` 或 `AppColor.onPrimary`（若适用）。
- 仅 `!followLatest && maxScrollExtent > 0` 时可见。

### 4. 三端接入

| 表面 | 改法 |
|------|------|
| 喂养 / 成长 | 删除私有 pane，直接 `AiThinkingPane(text, accentColor: deep)` |
| 诊疗流式 | `_ThinkingBlock` 在 `streaming==true` 时正文用 `AiThinkingPane`（保留标题「思考中…」、Stop） |
| 诊疗展开 | `thinkingExpanded==true` 时正文用 `AiThinkingPane` |
| 诊疗折叠 | **保持**现有尾部 Clip/`Align`，不接入 jumpTo（遵守 fold 规格） |

### 5. 全局约束写入

在 `openspec/project.md` 新增「AI 思考展示组件（强制）」；`AGENTS.md` 增加摘要并指回。归档后基线含 `ai-thinking-pane`。

## Risks / Trade-offs

- **[Risk] 诊疗流式限高后气泡变矮** → 用与分析页一致的 0.4 屏或略小 maxHeight；手工调。
- **[Risk] 滚动监听把程序 jumpTo 误判为用户上翻** → jump 期间加 `_programmaticScroll` 门闩，忽略 listener。
- **[Trade-off] 近底不自动恢复** → 符合产品明确要求；用户须点按钮。

## Migration Plan

1. 落地组件 + 文档约束。
2. 迁喂养 / 成长 / 诊疗。
3. 手工：三处流式跟底、上翻暂停、仅按钮恢复、按钮配色。
4. 回滚：恢复私有 pane / `_ThinkingBlock` 正文即可。

## Open Questions

- 无。

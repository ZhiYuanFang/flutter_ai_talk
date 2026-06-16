## Why

胖宝诊疗页 `_ThinkingBlock` 在折叠态依赖内层 `SingleChildScrollView` 自动 `jumpTo` 底部以跟随流式 thinking，但受布局时机与 `\n` 行数误判影响，折叠视口常停留在最旧内容，且用户侧未出现「跟随最新」提示。产品决策改为：**折叠态直接展示尾部内容窗口**，流式更新天然跟随最新，避免内层滚动竞态。

## What Changes

- 折叠态（`thinkingExpanded == false`）不再依赖内层滚动到底；改为在固定高度窗口内 **仅渲染 thinking 文本尾部**（约 5 行视觉高度），流式 `thinking_delta` 时始终可见最新片段。
- 展开态（点击「点击展开」后）展示完整 thinking，可内滚查看历史；折叠与展开切换语义保持不变。
- 移除或大幅简化折叠态下的 `ScrollController` 自动跟随、`thinkingInnerPinned` 与「跟随最新」chip（仅展开态长文需要用户滚动时可选保留 pin，或 v1 一并移除内层 pin 逻辑）。
- 折叠溢出提示改为基于 **视觉行高/布局测量** 或尾部裁剪结果，不再仅用 `\n` 计数判定是否溢出。
- 不影响外层聊天气泡滚动、answer Markdown 渲染、WS 协议。

## Capabilities

### New Capabilities

- `pangbao-clinic-thinking-fold`：胖宝诊疗思考块折叠尾部窗口、展开全文、流式跟随与溢出提示行为。

### Modified Capabilities

（无。`openspec/specs/` 基线尚无胖宝诊疗思考块独立 capability。）

## Impact

- **Flutter**：`app/lib/ui/pangbao_ai_screen.dart`（`_ThinkingBlock`、`_ChatItem.thinkingInnerPinned` 等）；可能抽取小型 tail 文本工具至 `app/lib/ui/widgets/`（实现期可选）。
- **不在范围**：后端 thinking 字段、Clinic WS 帧、answer 区 Markdown、自动化测试文件。

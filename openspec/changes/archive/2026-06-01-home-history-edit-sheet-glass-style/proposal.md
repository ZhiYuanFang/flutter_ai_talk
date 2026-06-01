## Why

主页历史编辑 Sheet 当前为默认 Material 底栏样式（系统 surface、Outlined 输入框、纵向堆叠按钮），与产品参考稿的玻璃拟态（Glassmorphism）视觉差距较大，品牌感与层级不清晰。需在**不改变编辑能力**的前提下，按参考图优化弹层观感。

## What Changes

- **玻璃拟态容器**：编辑 Sheet 主体采用半透明磨砂背景、轻渐变、圆角与微光描边；Modal 背景可半透明遮罩以突出卡片。
- **头部**：右上 **关闭（×）**；顶部居中 **事件 Logo** + **事件名标题**（大号白色/主题前景），替代现 `EventNameHeader` 横排样式。
- **时间字段**：「开始时间」「结束时间」标签 + **玻璃质感输入条**（大号 `HH:mm`、右侧 **铅笔** 编辑图标）；交互仍为点击打开滚轮 Sheet。
- **底部操作**：**取消**（纯文本，左）+ **保存**（实心圆角 pill，右）；删除/停止等次要操作改为与视觉稿协调的次级样式（文本或描边，不抢主 CTA）。
- **备注 / 用量滚轮**：沿用现有能力，输入区视觉与时间字段统一为玻璃边框风格。
- **非目标变更**：`eventNumber` 字段规则、pending 只读、API、路由逻辑不变。

## Capabilities

### New Capabilities

- `home-history-edit-sheet-glass-visual`：编辑 Sheet 玻璃拟态布局、头部、时间条、底栏 CTA 视觉规范。

### Modified Capabilities

- `home-history-edit-sheet`（变更 `home-history-edit-sheet`）：补充视觉呈现要求，功能需求不变。
- `app-bottom-sheet-layout`（变更 `home-history-edit-sheet`）：编辑 Sheet 可使用透明 sheet 背景 + 内层玻璃卡片（不影响其他 Sheet 默认样式）。

## Impact

- `app/lib/ui/home_history_edit_sheet.dart` — 布局与样式重构
- 新增或扩展：`home_history_edit_glass_sheet.dart`（或同类 shell 组件）
- `app/lib/ui/home_history_time_wheel.dart` — `HomeHistoryTimeField` 玻璃样式变体
- `app/lib/ui/widgets/app_adaptive_bottom_sheet.dart` — 可选参数（透明背景 / 无 drag handle）
- 无 API 变更

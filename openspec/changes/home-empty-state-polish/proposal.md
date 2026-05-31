## Why

主页在未绑定宝宝信息或今日无历史记录时，页面呈现大面积空白，且顶部的绑定入口较为单一和冷淡。这导致新用户或处于空闲状态的用户（无今日记录）无法感知到产品的温暖和指引。通过在空状态下引入更拟物的 3D 渲染风格宝宝动画，可以弥补视觉上的单调感，提升品牌亲和力，并以更自然的方式邀请用户进行绑定或记录操作。

## What Changes

- **引入动画依赖**: 在 `pubspec.yaml` 中新增 `lottie` 插件，用于承载 3D 风格的高度压缩矢量/图层动画。
- **主页空状态重构**:
  - **未绑定宝宝状态**: 在页面中心展示“胖宝”挥手招呼的 3D 动画，配合清晰的“立即绑定宝宝”操作按钮。
  - **已绑定无记录状态**: 展示宝宝进食、睡觉或玩耍等随机/固定 3D 动画，并通过文字提示引导用户点击下方输入区（语音/文本/按钮）开始记录今日的第一笔数据。
- **UI 布局动态调整**:
  - 当显示大幅空状态动画时，自动隐藏顶部的 `HomeTodaySummaryPanel`（今日概览面板）以及原有的 `showBindBanner`，确保视觉焦点处于中央。
  - 优化 `HomeHistoryScroll` 与空状态视图的切换过渡。

## Capabilities

### New Capabilities
- `home-empty-state-visuals`: 规范主页在各种空状态（未登录、未绑定、无记录）下的视觉占位、动画交互以及引导逻辑。

### Modified Capabilities
- 无：本次变更仅涉及 UI 表现层与展示逻辑的优化，不涉及后端 API 定义或核心业务流程的修改。

## Impact

- **pubspec.yaml**: 新增 `lottie` 依赖。
- **app/lib/ui/home_screen.dart**: `build` 方法中的 `body` 渲染层级将引入新的分支逻辑。
- **assets/images/**: 需要增加若干 Lottie 动画文件（如 `ani_baby_welcome.json`, `ani_baby_feeding_guide.json`）。
- **性能影响**: Lottie 动画渲染对低端机型有一定开销，需确保动画文件大小经过优化。

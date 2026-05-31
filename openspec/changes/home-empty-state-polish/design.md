## Context

目前 `HomeScreen` 在没有任何记录（或未绑定宝宝）时，直接展示简单的 `Center(child: Text(...))` 或者顶部的一行小 Banner。对于主打母婴记录的产品，初次使用的空状态是建立用户连接的关键时刻。目前的“冷暴力”式空白缺乏情绪价值。

## Goals / Non-Goals

**Goals:**
- 提供温馨、有亲和力的 3D 动画引导界面。
- 引导用户完成“绑定”或“记录”的核心动作。
- 保持布局简洁，避免在空状态下展示无意义的 UI 元素（如空的统计面板）。

**Non-Goals:**
- 不涉及后台数据的逻辑变更。
- 不更改现有的正常记录展示流程（当有记录时，一切恢复原样）。

## Decisions

### 1. 采用 Lottie 动画库 (Choice: Lottie)
- **Rationale**: 相比于 Rive，Lottie 拥有更庞大的 3D 风格（预渲染图层）资源库。对于“拟物 3D 风”，Lottie 能更完美地复现 C4D/Blender 的渲染效果。
- **Alternatives**: 原生 Flutter 动画（过于复杂，难以实现 3D 效果）、GIF（质量低且体积大）。

### 2. 状态驱动的分支渲染逻辑
- **HomeScreenRefactor**: 修改 `HomeScreen` 的 `body` 块，引入三个渲染状态：
  - `_EmptyStateBinding`: 当 `needsDeviceBind` 为真。
  - `_EmptyStateRecording`: 当 `historyItems.isEmpty && !needsDeviceBind && historyInitialLoadDone`。
  - `NormalList`: 当 `historyItems.isNotEmpty`。
- **UI Suppression**: 当处于前两个 Empty 状态时，`HomeTodaySummaryPanel` 将返回 `SizedBox.shrink()`，通过逻辑控制确保页面清爽。

### 3. 组件化引导页 (HomeEmptyStateGallery)
- 创建内部私有 Widget `_HomeEmptyStateGallery`，接收 `animationPath`、`title`、`subtitle` 和 `actionButton` 参数，统一管理 3D 动画的缩放、文字排版和氛围渲染。

## Risks / Trade-offs

- **[Risk] Lottie 内存占用** → **Mitigation**: 限制动画时长在 2-3 秒内循环，并使用 `Lottie.asset` 的缓存功能。确保动画文件经过 JSON 压缩优化。
- **[Risk] 资源文件缺失导致崩溃** -> **Mitigation**: 增加 `errorBuilder` 回滚到现有的文字展示模式，确保程序健壮性。
- **[Risk] Web 端兼容性** -> **Mitigation**: Lottie Web 支持良好，但在 `Canvas` 模式下可能需要特定加载配置，需在 Web 环境验证。

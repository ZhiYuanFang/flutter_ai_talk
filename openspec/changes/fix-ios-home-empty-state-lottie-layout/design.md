## Context

主页空状态由 `home_screen.dart` 内私有组件 `_HomeEmptyStateGallery` 渲染，使用 `lottie` 包加载 `assets/images/ani_baby_welcome.json`（未绑定）与 `ani_baby_feeding_guide.json`（已绑定无记录）。当前仓库中两文件均为 `{}` 占位（2 字节），在 Android 上 Lottie 大致遵守 `width`/`height: 240`，标题、副标题与「立即绑定宝宝」按钮可见；在 iOS 上 Lottie 在嵌套 `Expanded` → `Column(mainAxisAlignment: center, mainAxisSize: max)` 中撑满中间区域，兄弟 Text/Button 被裁出可视区，用户仅见灰色块。

基线 `home-empty-state-visuals` 已规定未绑定/无记录时的邀请与鼓励视图，但未明确跨平台布局 parity 与 Lottie 失败兜底。本变更在不动业务分支的前提下修复 iOS 渲染。

## Goals / Non-Goals

**Goals:**

- iOS 与 Android 在未绑定、无记录两种空状态下，标题、副标题、主操作按钮（未绑定）均必须位于可视区内且可交互。
- Lottie 动画区尺寸可预期（约 240×240 logical px），不得占满历史 `Expanded` 导致 siblings 不可见。
- Lottie 加载失败或无效 JSON 时，动画槽位展示静态兜底（图标或 PNG），文案与按钮仍必须展示。

**Non-Goals:**

- 不修改 `deviceNo` 判定、`showBindBanner`、WS 横幅或历史加载状态机。
- 不强制在本变更内接入最终 3D Lottie 设计稿（可后续单独 PR 替换 JSON）。
- 不新增自动化测试文件（遵循仓库规则，以 iOS/Android 手工验证为主）。

## Decisions

### 1. 布局：硬约束 + 最小 Column + Center

**选择**：将 `_HomeEmptyStateGallery` 改为 `Center` → `Column(mainAxisSize: MainAxisSize.min)` → `SizedBox(width: 240, height: 240, child: Lottie(...))` → 文案 → 按钮。

**理由**：当前 `Column` 默认 `mainAxisSize: max` 占满 `Expanded` 高度，iOS Lottie 易突破 240 约束；`min` + 外层 `Center` 使内容总高度由子项决定，避免居中溢出裁切。

**备选**：`SingleChildScrollView` 包裹整列——可应对极小屏，但空状态内容不多，优先 min Column；若验证仍溢出再加 ScrollView。

### 2. Lottie iOS 灰框：`addRepaintBoundary: false`

**选择**：在 `Lottie.asset` 上设置 `addRepaintBoundary: false`。

**理由**：lottie-flutter 社区在 iOS 上对 RepaintBoundary 相关灰框有 reported workaround；与硬 `SizedBox` 组合使用，风险低。

**备选**：Platform 分支仅 iOS 设置——若 Android 无回归可全平台统一 false。

### 3. 兜底：`errorBuilder` + 固定尺寸槽位

**选择**：保留 `errorBuilder`，返回与动画同尺寸的 `Icon` 或 `Image.asset`（如 `event_placeholder.png` 或专用 empty-state PNG）；动画槽与文案解耦，文案不依赖 Lottie 成功。

**理由**：`{}` 在 iOS 可能不触发 `errorBuilder` 却渲染空灰块；硬 `SizedBox` + `clipBehavior: Clip.hardEdge` 限制视觉范围；若仍无有效帧，可在 `frameBuilder` 首帧为空时使用同一静态兜底（实现时二选一，以可见性为准）。

**备选**：完全弃用 Lottie 改用 PNG——简单但偏离 spec 中「3D 动画」表述；本变更保留 Lottie 路径并修布局。

### 4. 资源：布局修复优先，JSON 替换可选

**选择**：本变更以布局与兜底为主；若设计未提供 JSON，不阻塞合并。

**理由**：探索已确认 Android 在 `{}` 下文案可见，说明布局是 iOS 主因；替换 JSON 为体验增强而非修复必要条件。

## Risks / Trade-offs

- **[Risk] 极小屏高度不足，按钮仍被底栏遮挡** → 验证 iPhone SE 类设备；必要时对空状态区加 `SingleChildScrollView` 或略减动画尺寸。
- **[Risk] `addRepaintBoundary: false` 影响重绘性能** → 空状态非高频动画场景，可接受。
- **[Risk] `{}` 在 iOS 仍占满 SizedBox 内灰区** → 用户仍见灰块但文案/按钮可见，较当前不可用状态已达标；配合 PNG 兜底可改善。
- **[Trade-off] 未在本变更实现 Layout Auto-Suppression（隐藏 TodaySummaryPanel）** → 基线已有要求但属独立缺口；空状态 `totals.isEmpty` 时已 shrink，影响小。

## Migration Plan

- 单 PR 修改 `_HomeEmptyStateGallery`（及可选 assets）。
- 发布前在 iOS 真机/模拟器验证：未绑定无记录、已绑定无记录两种路径。
- 回滚：还原 `home_screen.dart` 中该组件即可，无数据迁移。

## Open Questions

- 设计是否近期提供正式 `ani_baby_welcome.json` / `ani_baby_feeding_guide.json`？若提供，可在 follow-up 替换 `{}` 而不改布局结构。
- 未绑定场景按钮文案基线为「立即绑定宝宝信息」，代码为「立即绑定宝宝」——实现时是否统一字符串（非本变更阻塞项）。

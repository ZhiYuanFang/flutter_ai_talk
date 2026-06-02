## Why

iOS 端在未绑定或无历史记录时，主页空状态 `_HomeEmptyStateGallery` 中的 Lottie 占位（当前为 `{}` stub）在嵌套 `Expanded` + `Column` 布局下会撑满中间区域并裁切下方文案与按钮，用户仅看到大片灰色块；Android 同场景可正常显示「嗨，我是胖宝！」与「立即绑定宝宝」。该问题导致 `home-empty-state-visuals` 基线在 iOS 上未实际满足，需修复布局与兜底渲染以保证跨平台一致。

## What Changes

- 重构 `_HomeEmptyStateGallery` 布局：对 Lottie 施加硬尺寸约束（如 `SizedBox`）、内层 `Column` 使用 `mainAxisSize: min` 并外包 `Center`，必要时启用 `addRepaintBoundary: false`，防止 iOS 上动画层占满 `Expanded` 导致 siblings 被挤出可视区。
- 增强空状态动画加载失败或无效 JSON 时的兜底：在 `errorBuilder` 或等价路径展示静态占位图/图标，并**仍必须**渲染标题、副标题与操作按钮（未绑定场景）。
- （可选、非阻塞）在 `assets/images/` 替换 `{}` 占位 Lottie 为有效 JSON 或补充 PNG 静态资源，改善动画区观感；若暂无设计资源，布局修复 + 静态兜底即可恢复 iOS 可用性。
- 不改变未绑定/无记录的业务分支逻辑、`deviceNo` 判定或路由行为。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-empty-state-visuals`：补充 iOS 与 Android 空状态视觉 parity 及 Lottie 失败兜底的可验收要求。

## Impact

- **代码**：`app/lib/ui/home_screen.dart`（`_HomeEmptyStateGallery` 及可能的空状态相关布局）。
- **资源**：`app/assets/images/ani_baby_welcome.json`、`ani_baby_feeding_guide.json`（可选替换或新增 PNG 兜底）。
- **依赖**：现有 `lottie` 包，无新增依赖预期。
- **API/契约**：无后端或对外 API 变更；用户可见行为为 iOS 空状态恢复展示文案与按钮。

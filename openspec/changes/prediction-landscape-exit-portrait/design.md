## Context

- 竖屏顶栏投屏按钮（`Icons.cast`）确认后调用 `SystemChrome.setPreferredOrientations([landscapeLeft, landscapeRight])`，对话框写「需重启应用才能退出」。
- 横屏布局已由 `prediction-landscape-column-scale` 引入右三栏：左身份 | 中瀑布 | 右密度轨（36px 宽，`拖动调整大小` + 满高轨道）。
- `_PredictionLandscapeImmersiveHost` 在 `isLandscape && predictionVisible` 时开沉浸/常亮，回竖屏自动 `_release()`。
- `ucg_media_viewer` 已有 `_restoreSystemChrome` → `DeviceOrientation.values` 先例。

## Goals / Non-Goals

**Goals:**

- 右密度栏顶部的单点退出：强制回到竖屏并恢复全方向旋转。
- 与投屏入口对称、可发现；更新误导性对话框文案。
- 右栏 36px 宽内可点（紧凑命中区，不挤占密度轨 drag 区）。

**Non-Goals:**

- 不改变进入投屏时的 landscape 锁定语义。
- 不新增全局「投屏模式」持久化状态机。
- 不处理卡片 header 开关文案布局（属 `prediction-landscape-column-scale` 或后续 change）。

## Decisions

### 1. 退出时序：先竖屏，再恢复全方向

**选择**：`portraitUp` → 短延迟或下一 frame → `DeviceOrientation.values`。

**理由**：当前仅允许 landscape，单次 `values` 不一定立刻旋转；先 `portraitUp` 保证 UI 立即回竖屏，再 `values` 满足「恢复全方向」。

**备选**：仅 `values` — 用户可能仍停在横屏直到手动转手机；不符合「转竖屏」。

### 2. 按钮位置与尺寸

**选择**：`_LandscapeColumnDensitySideRail` 的 `Column` 最上方；`Material` + `InkWell` / `Icon(size: 20)`，约 36×36 命中区；`Tooltip('返回竖屏')`。

**理由**：36px  rail 放不下标准 48px `IconButton`；顶部与密度轨 drag 区域分离。

### 3. Helper 抽取

**选择**：在 `smart_prediction_screen.dart` 内 `Future<void> _exitLandscapeToPortrait()` 或同级 top-level/private 函数；投屏入口与右栏共用「进入 landscape 锁定」与「退出并恢复 values」。

**理由**：最小 diff；若后续多页复用再抽到 `lib/ui/orientation_utils.dart`。

### 4. 投屏对话框文案

**选择**：将「需重启应用才能退出」改为「进入后可在横屏右侧点击返回竖屏图标退出」类表述；保留投屏操作说明。

## Risks / Trade-offs

- [36px 命中区偏小] → Tooltip + Semantics；7 列场景用户可调列数或旋转手机，可接受。
- [iOS/Android 方向 API 时序差异] → `portraitUp` 后 `await Future.delayed` 一帧或 100ms 再 `values`；真机验证。
- [与 column-scale 并行合并冲突] → 仅改 SideRail 顶部与 Screen 层 helper；右栏 Row 结构不变。

## Migration Plan

- 纯客户端 UI；发版即生效，无数据迁移。
- 回滚：移除按钮并恢复旧对话框文案。

## Open Questions

（无 — 用户已确认退出后恢复全方向 `DeviceOrientation.values`。）

## Context

`prediction-landscape-rail` 已实现预测页横屏左竖排身份 + 右三列瀑布，但页面仍包在 `SafeArea` 下，系统状态栏可见，且无防熄屏。UCG 媒体查看器已有 `SystemUiMode.immersiveSticky` / 恢复 `edgeToEdge` 范例。仓库尚无 wakelock 依赖。

## Goals / Non-Goals

**Goals:**

- 预测页可见 + 横屏：沉浸隐藏系统状态栏（sticky）、最大化内容区、启用常亮。
- 回竖屏或离开预测页：恢复系统 UI、关闭常亮。
- 与媒体全屏 SystemChrome 尽量成对、可恢复。

**Non-Goals:**

- 不改喂养/UCG 页横屏行为。
- 不强制锁定横屏方向（用户仍可自由旋转）。
- 不要求 Web 支持 SystemChrome/wakelock。
- 不新建测试文件。

## Decisions

### D1. 作用面：仅预测页 × 横屏

- 在 `SmartPredictionScreen`（或包一层 Stateful 宿主）根据 `MediaQuery.orientation` + 挂载生命周期驱动。
- 壳层滑到喂养/广场：预测页 dispose/不可见时释放；若 KeepAlive 需在可见性变化时 disable（优先用 `AutomaticKeepAliveClientMixin` 可见回调或 pager index listen）。

### D2. System UI：`immersiveSticky`

- 进入：`SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`（非 Web）。
- 离开/竖屏：`SystemUiMode.edgeToEdge`（对齐媒体查看器）。
- 横屏 `SafeArea`：`top: false, bottom: false`（或横屏不用 SafeArea）；竖屏保持现有 SafeArea。

### D3. 防熄屏：`wakelock_plus`

- 新增依赖 `wakelock_plus`；横屏预测启用 `WakelockPlus.enable()`，退出 `disable()`。
- 失败路径用既有 Debug 出口记录（若需），不得裸 print。

### D4. 与媒体查看器共存

- 媒体页仍自管进出。预测页仅在「自己持有沉浸」时恢复；若用户从预测横屏进媒体再返回，媒体恢复 edgeToEdge 后预测若仍横屏应再次 enable（在 resume/可见时重入检查）。

### D5. KeepAlive 可见性

- `/home` PageView 可能 KeepAlive 预测页：除 orientation 外，须结合 `homePagerIndexProvider == prediction`（或等价）才启用沉浸+wakelock；滑走即 disable。

## Risks / Trade-offs

- [KeepAlive 导致滑走后仍常亮] → D5 绑 pager index。
- [与媒体 SystemChrome 竞态] → 进出成对 + 可见时重同步。
- [iOS/Android 沉浸手势可临时唤出系统栏] → sticky 可接受。
- [耗电] → 仅横屏预测开启，产品取舍。

## Migration Plan

- 纯客户端；回滚移除 lifecycle 与依赖即可。

## Open Questions

- （无；范围 A + immersiveSticky + wakelock_plus 已确认。）

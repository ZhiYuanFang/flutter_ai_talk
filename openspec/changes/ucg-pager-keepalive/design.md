## Context

- `/home` 为三页 PageView：`feeding=0`、`prediction=1`（默认）、`ucg=2`（见 `HomePagerPage`）。基线 `ucg-home-entry` 文案仍写旧 index（陪伴/喂养），实现已迁到预测居中；本变更不重写整页索引规格，只补 UCG KeepAlive。
- 喂养有 `_KeepAliveHomeScreen`，预测有 `_KeepAlivePredictionPage`；UCG 在 `itemBuilder` 直接 `return UcgShell(...)` / `FeatureLockOverlay(child: shell)`，无 KeepAlive。
- `_ucgEverMounted` 只控制「首次前返回空占位」，首次后仍每次 dispose/remount。
- `UcgSquareTab.initState` → `_load(refresh: true)` 在每次新挂载跑推荐首刷；这是预期的**冷挂载**行为，问题在挂载太频繁。

## Goals / Non-Goals

**Goals:**

- 首次进入 UCG 后滑走再回来：保留 `UcgShell` / 广场 State（列表、滚动、Tab、模式）。
- 不破坏懒挂载与冷启不刷推荐 / 不弹定位。
- 与现有 `_KeepAlivePredictionPage` 模式对齐，改动面小。

**Non-Goals:**

- 不改推荐算法、Feed API、定位策略。
- 不强制改 `UcgSquareTab` 的 postsChanged / 下拉刷新逻辑。
- 不重写基线里过时的 PageView index 叙述（另 change 处理）。
- 不新建测试文件。

## Decisions

### 1. 包装 `_KeepAliveUcgPage`（与预测同构）

新增 Stateful/ConsumerStateful 包装，`with AutomaticKeepAliveClientMixin`，`wantKeepAlive => true`，`build` 里 `super.build` 后挂载现有 `UcgShell`（及必要时外包的 `FeatureLockOverlay`）。

**资格锁态注意**：今日结构是 `ref.watch(ucgEligibilityStateProvider)` 后在 qualified 时返回 `shell`，否则 `FeatureLockOverlay(child: shell)`。KeepAlive 包装应包住**整棵**返回子树（锁或未锁），避免资格边沿重建时丢掉保活。推荐：

```
return _KeepAliveUcgPage(
  child: eligibility.isQualified ? shell : FeatureLockOverlay(..., child: shell),
);
```

或让 KeepAlive 页内部 watch eligibility（二选一；优先外层与现逻辑一致、KeepAlive 仅包 child）。

**理由**：最小对称修复。  
**备选**：只给 `UcgSquareTab` KeepAlive——拒，壳与其它 Tab 仍会拆。

### 2. 懒挂载闸门不变

仍用 `_ucgEverMounted`：未进过 UCG 返回 `SizedBox.expand()`；首次 `_onPageChanged` → `_markUcgMounted` 后才 build KeepAlive 子树。KeepAlive **不得**在首次前预热。

### 3. 不改广场 initState 首刷

KeepAlive 生效后，往返不再 remount，自然不再重复 `_load(refresh: true)`。保留 initState 首刷给真·首次进入。

### 4. （可选）资格 `ensureLoaded` 已 ready 短路

`_onPageChanged` 进 UCG 时现有 `ensureLoaded()` 每次可能打 HTTP。可在 notifier 内若已 `ready` 且数据新鲜则 return；属顺手优化，失败不得阻塞 KeepAlive 主修复。

## Risks / Trade-offs

- **[Risk] 常驻 UCG 增加内存** → 与预测页同权衡；可接受。
- **[Risk] 资格从不合格→合格时 Overlay 变壳** → 子树结构变化可能仍 rebuild；KeepAlive 保住 State 后，广场 eligibility listen 已有首刷逻辑（`!_initialLoaded`），需手工确认解锁路径不双刷或漏刷。
- **[Trade-off] 列表可能略旧直到用户下拉** → 符合「不要每次滑动刷新」预期。

## Migration Plan

1. 在 `ucg_home_shell.dart` 增加 KeepAlive 包装并接入 itemBuilder。
2. 手工：预测↔UCG 多次往返，推荐列表与滚动位置保持；冷启未进 UCG 无定位弹窗/无推荐请求。
3. 回滚：去掉包装即可。

## Open Questions

- 无。

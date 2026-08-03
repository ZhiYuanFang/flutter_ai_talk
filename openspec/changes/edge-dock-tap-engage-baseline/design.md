## Context

`extract-edge-dock-shell` 已抽出 `EdgeDockShell`（peek / engaged / floating、累计拉入、热区、锁滑），模式球与 tip 球挂壳。tip 仍开 `externalPeekEngage`，半圆点按直接展开大卡，迫使宿主写「点缩进球」专用逻辑。产品冻结：**点按永远只 engage；只允许拉满后自动业务；半圆点击逻辑属壳基线，宿主不写。**

## Goals / Non-Goals

**Goals:**

- 壳基线唯一：peek 点按 → engaged；peek 拉满 → engage，并可选触发宿主「拉满业务」回调。
- 宿主业务（切模式、展开 tip）只挂在 engaged / floating 的 `onInteractiveTap`，或拉满可选回调；**不为 peek 点按写分支。**
- tip / 模式球去掉 `externalPeekEngage` 旁路。

**Non-Goals:**

- 不重做几何、热区、锁滑。
- 不把 tip 展开大卡拖进壳。
- 不改模式球「拉满自动切模式」（默认不自动业务）。

## Decisions

### 1. 手势语义（基线）

| 状态 / 手势 | 壳行为 | 宿主 |
|-------------|--------|------|
| peek + 点按 | 仅 `_engage()` → 全圆 | **无回调** |
| peek + 累计向内 ≥ 阈值 | `_engage()`；若配置了 `onPullBusiness` 则紧接着调用 | tip：展开；模式：null |
| engaged / floating + 点按 | 调用 `onInteractiveTap` | tip：展开；模式：cycle |
| 拖动松手吸附 | 既有 snap 逻辑 | 持久化等 |

### 2. API 收敛

- **删除** `externalPeekEngage` 与 peek 点按路径上的 `onPeekEngage`（或保留参数但永久忽略并 deprecate，优先删除以免旁路重生）。
- **新增**（可选）`onPullBusiness`：仅在拉满阈值触发，点按永不走此回调。
- tip：`onInteractiveTap` + `onPullBusiness` 均可指向同一 `_expandFromBall`；半圆点按无 tip 代码。
- 模式球：只挂 `onInteractiveTap`；`onPullBusiness` 不传。

### 3. 与上一 change 的关系

- 本变更是对 `extract-edge-dock-shell` 行为的增量收紧；实现时直接改共享壳与 tip 接线，并更新该 change 中过时的 tip「点 peek 即展开」表述（若仍未归档，以本 change spec 为准）。

### 4. 备选否决

- **保留 externalPeekEngage**：否决——宿主仍会写半圆点击逻辑。
- **拉满也只 engage、永不自动业务**：否决——与「拉满后自动业务」产品句冲突；用可选回调兼顾模式球。

## Risks / Trade-offs

- [模式球两击] → peek 点按只露出全圆，再点才切模式；与「对齐模式球」一致，若旧版曾「一点半圆就切」则以手工 1.4 对照；当前壳默认已是两步。
- [拉满误触展开 tip] → 阈值沿用壳 `pullInThreshold`（约 28）；可后续调参，不单开 tip 阈值。
- [与 extract change 文档冲突] → apply 时同步改 tip 接线；归档时以本 delta 为准。

## Migration Plan

1. 改壳 API / 手势分支。  
2. tip 去掉旁路，挂 tap + pull business。  
3. 模式球确认未传旁路。  
4. 手工：半圆点=全圆；拉满 tip 展开；全圆点 tip/模式业务。

回滚：恢复 `externalPeekEngage` tip 接线（不推荐）。

## Open Questions

- 无（点按只 engage、拉满可选自动业务、宿主不写半圆点击 已冻结）。
